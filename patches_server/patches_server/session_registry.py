from dataclasses import dataclass, timedelta
from datetime import datetime
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
    _registry: Dict[str, SessionState] = {}

    def timed_out(self, timeout_seconds):
        '''
        '''


    def notify_activity(self, session_id):
        '''
        '''


    def queue(self, session_id, platform):
        '''
        '''


    def activate(self, max=None):
        '''
        '''


    def terminate(self, session_id):
        '''
        '''