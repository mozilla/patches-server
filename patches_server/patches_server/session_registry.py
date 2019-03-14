from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import json
from typing import Dict

from persist import State


class ActivityState(Enum):
    '''Sessions can be either active or queued for later handling.
    '''

    QUEUED = 0
    ACTIVE = 1


@dataclass
class SessionState:
    '''A record of the state that a session is currently in.
    '''

    scanning_platform: str
    state: ActivityState = ActivityState.QUEUED
    created_at: datetime = datetime.utcnow()
    last_heard_from: datetime = datetime.utcnow()
    vulns_read: int = 0

    def is_expired(self, timeout_seconds):
        '''Determine if a session has expired by checking if some number of
        seconds have passed since the scanner that owns the session has been
        heard from.
        '''
        
        delta = timedelta(seconds=timeout_seconds)

        return self.last_heard_from + delta <= datetime.utcnow()

    
    def notify_activity(self, read_vulns=0):
        '''Update the session state's record of the last time the owner was
        heard from with the current time.
        '''

        self.last_heard_from = datetime.utcnow()
        self.vulns_read += read_vulns

        return self

    
    def activate(self):
        '''Update the state of a session to indicate that it is now being
        served vulnerabilities.
        '''

        self.state = ActivityState.ACTIVE
        
        return self


    def to_json(self):
        '''Convert to a JSON representation.
        '''

        state_str = lambda s: 'active' if s == ActivityState.ACTIVE else 'queued'

        return json.dumps({
            'platform': self.scanning_platform,
            'state': state_str(self.state),
            'createdAt': str(self.created_at),
            'lastHeardFrom': str(self.last_heard_from),
            'vulnerabilitiesRead': self.vulns_read
        })


    @staticmethod
    def from_json(json_str):
        '''Parse a string containing JSON into a SessionState, provided
        the JSON contains all required fields.
        Returns None if the JSON is invalid.
        '''

        parsed = {}

        try:
            parsed = json.loads(json_str)
        except json.decoder.JSONDecodeError:
            return None

        platform = parsed.get('platform', None)
        state = parsed.get('state', None)
        created_at = parsed.get('createdAt', None)
        last_heard = parsed.get('lastHeardFrom', None)
        vulns_read = parsed.get('vulnerabilitiesRead', None)

        all_values = [ parsed, state, created_at, last_heard, vulns_read ]

        if any(value is None for value in all_values):
            return None

        state_enum = ActivityState.ACTIVE\
            if state == 'active'\
            else ActivityState.QUEUED

        parse_date = lambda ds: datetime.strptime(ds, '%Y-%m-%d %H:%M:%S.%f')

        return SessionState(
            platform,
            state_enum,
            parse_date(created_at),
            parse_date(last_heard),
            vulns_read)


@dataclass
class SessionRegistry(State):
    '''Tracks the state of sessions, identified by a string identifier, and
    facilitates session management.
    '''

    max_active_sessions: int = 128
    max_queued_sessions: int = 1024
    _registry: Dict[str, SessionState] = field(default_factory=dict)

    def persist(self, redis):
        '''Store registry state and configuration to Redis.
        '''

        try:
            redis.set(
                'session_registry_max_active_sessions',
                self.max_active_sessions)

            redis.set(
                'session_registry_max_queued_sessions',
                self.max_queued_sessions)

            for session_id, session_state in self._registry.items():
                redis.hset(
                    'session_registry',
                    session_id,
                    session_state.to_json())

        except Exception as ex:
            return ex

        return None


    def rebuild(self, redis):
        '''Reconstruct the registry state from Redis.
        '''

        max_active = redis.get('session_registry_max_active_sessions') or 128
        
        max_queued = redis.get('session_registry_max_queued_sessions') or 1024

        session_ids = redis.hkeys('session_registry')

        registry = {}

        for session_id in session_ids:
            state_str = redis.hget('session_registry', session_id)

            if state_str is None:
                continue

            state = SessionState.from_json(str(state_str))

            if state is None:
                continue

            registry[session_id] = state

        self.max_active_sessions = max_active

        self.max_queued_sessions = max_queued

        self._registry.update(registry)

        return self


    def timed_out(self, timeout_seconds):
        '''Determine which sessions have expired.
        Returns a list of the ids of sessions found to be expired.
        '''

        return [
            id
            for (id, session) in self._registry.items()
            if session.is_expired(timeout_seconds)
        ]

    
    def lookup(self, session_id):
        '''Search the registry for a session, returning a copy of its
        ServerState if it exists, or else None.
        '''

        if self._registry.get(session_id, None) is None:
            return None

        state = self._registry[session_id]

        return SessionState(
            state.scanning_platform,
            state.state,
            state.created_at,
            state.last_heard_from,
            state.vulns_read,
        )


    def active(self, read_at_least=None, platform=None):
        '''Determine which sessions are active and, optionally, satisfy either
        or both of the following conditions:

            * have read at least some number of vulns
            * are scanning on a particular platform
        '''

        N = lambda a: a is None

        return [
            id
            for (id, session) in self._registry.items()
            if session.state == ActivityState.ACTIVE and\
                (N(read_at_least) or session.vulns_read >= read_at_least) and\
                (N(platform) or session.scanning_platform == platform)
        ]


    def notify_activity(self, session_id, read_vulns=0):
        '''Update a session to indicate that it is still active.
        Returns True if the session exists, or else False.
        '''

        if session_id not in self._registry:
            return False

        new_state = self._registry[session_id]\
            .notify_activity(read_vulns=read_vulns)

        self._registry[session_id] = new_state

        return True


    def queue(self, session_id, platform):
        '''Queue a new session for a scanner running on a given platform.
        Returns True if there was room to queue the session, or else False.
        '''

        queued = [
            session
            for (_id, session) in self._registry.items()
            if session.state == ActivityState.QUEUED
        ]

        limit_exceeded = len(queued) >= self.max_queued_sessions

        already_registered = session_id in self._registry

        if limit_exceeded or already_registered:
            return False

        self._registry[session_id] = SessionState(platform)

        return True


    def activate_sessions(self, max=None):
        '''Mark up to a maximum number of sessions as active.
        Returns a list of IDs of sessions that were activated.
        '''

        active = [
            session
            for (_id, session) in self._registry.items()
            if session.state == ActivityState.ACTIVE
        ]

        queued = [
            [ id, session ]
            for (id, session) in self._registry.items()
            if session.state == ActivityState.QUEUED
        ]

        queued_by_created_at = sorted(
            queued, key=lambda pair: pair[1].created_at)

        num_to_activate = min([
            self.max_active_sessions - len(active),
            max if max is not None else self.max_active_sessions,
            len(queued),
        ])

        to_activate = queued_by_created_at[:num_to_activate]

        for [ session_id, session ] in to_activate:
            self._registry[session_id] = session.activate()

        return [ pair[0] for pair in to_activate ]


    def terminate(self, session_id):
        '''Terminate a session, removing it from the registry.
        Returns True if the session existed or else False.
        '''

        if session_id not in self._registry:
            return False

        self._registry.pop(session_id)

        return True
