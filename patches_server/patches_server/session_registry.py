from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Dict


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

    
    def notify_activity(self):
        '''Update the session state's record of the last time the owner was
        heard from with the current time.
        '''

        self.last_heard_from = datetime.utcnow()

        return self

    
    def activate(self):
        '''Update the state of a session to indicate that it is now being
        served vulnerabilities.
        '''

        self.state = ActivityState.ACTIVE
        
        return self


@dataclass
class SessionRegistry:
    '''Tracks the state of sessions, identified by a string identifier, and
    facilitates session management.
    '''

    max_active_sessions: int
    max_queued_sessions: int
    _registry: Dict[str, SessionState] = field(default_factory=dict)

    def timed_out(self, timeout_seconds):
        '''Determine which sessions have expired.
        Returns a list of the ids of sessions found to be expired.
        '''

        return [
            session_id
            for _index, (session_id, session_state) in enumerate(self._registry.items())
            if session_state.is_expired(timeout_seconds)
        ]


    def notify_activity(self, session_id):
        '''Update a session to indicate that it is still active.
        Returns True if the session exists, or else False.
        '''

        if session_id not in self._registry:
            return False

        old_state = self._registry[session_id] 
        self._registry[session_id] = old_state.notify_activity()

        return True


    def queue(self, session_id, platform):
        '''Queue a new session for a scanner running on a given platform.
        Returns True if there was room to queue the session, or else False.
        '''

        queued = [
            session
            for _index, (session_id, session) in enumerate(self._registry.items())
            if session.state == ActivityState.QUEUED
        ]

        already_registered = session_id in self._registry

        if len(queued) >= self.max_queued_sessions or already_registered:
            return False

        self._registry[session_id] = SessionState(platform)

        return True


    def activate(self, max=None):
        '''Mark up to a maximum number of sessions as active.
        Returns a list of IDs of sessions that were activated.
        '''

        active = [
            session
            for _index, (session_id, session) in enumerate(self._registry.items())
            if session.state == ActivityState.ACTIVE
        ]

        queued = [
            [ session_id, session ]
            for _index, (session_id, session) in enumerate(self._registry.items())
            if session.state == ActivityState.QUEUED
        ]

        queued_by_created_at = sorted(queued, key=lambda pair: pair[1].created_at)

        num_to_activate = min([
            self.max_active_sessions - len(active),
            max if max is not None else self.max_active_sessions,
            len(queued),
        ])

        to_activate = queued_by_created_at[:num_to_activate]

        for [ session_id, session ] in to_activate:
            new_session = session.activate()
            self._registry[session_id] = new_session

        return [ pair[0] for pair in to_activate ]


    def terminate(self, session_id):
        '''Terminate a session, removing it from the registry.
        Returns True if the session existed or else False.
        '''

        if session_id not in self._registry:
            return False

        self._registry.pop(session_id)

        return True