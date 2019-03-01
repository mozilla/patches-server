'''The ServerState class contains and provides a thread-safe interface for managing
the state handled between requests by the Patches-Server application.
'''

from dataclasses import dataclass, field
from os import urandom
from threading import Lock
from typing import Dict, Generator

from cache import Cache
from session_registry import SessionRegistry
import sources as sources
from vulnerability import Vulnerability 


@dataclass
class ServerState:
    '''Handles server state that must be shared between requests.
    '''

    _sessions: SessionRegistry = SessionRegistry(128, 1024)
    _cache: Cache = Cache()
    _source_configs: Dict[str, dict] = field(default_factory=dict)
    _active_sources: Dict[str, Generator[Vulnerability, None, None]] =\
        field(default_factory=dict)
    _max_vulns_to_serve: int = 128
    _session_timeout_seconds: int = 30
    _thread_safety_lock: Lock = field(default_factory=Lock)

    def configure(self, config):
        '''Configure otherwise default values used by the ServerState.

        The config parameter must be a dictionary containging a 'sources' key
        mapping to a dictionary itself mapping source identifiers to
        dictionaries containing configuration parameters for the corresponding
        source.

        The config parameter can also contain the following keys:

        * maxActiveSessions: int, the maximum number of sessions to allow to be
        active at any time. Defaults to 128.
        * maxQueuedSessions: int, the maximum number of sessions to queue for
        later activation. Defaults to 1024.
        * sessionTimeoutSeconds: int, the number of seconds after which no
        activity for a session indicates that it has timed out and should be
        removed. Defaults to 30.
        * maxVulnsToServe: int, the maximum number of vulnerabilities to serve
        to any single scanner in one request. Defaults to 128.

        Accepted source identifiers are:

        * clair

        Source configurations:

        Clair:

        * baseAddress: str, the base url pointing to a Clair instance.
        e.g. http://127.0.0.1:6060
        * fetchLimit: int, the maximum number of vulns to fetch in a single call
        to Client.retrieve_vulns.
        '''

        if 'sources' not in config:
            raise KeyError('ServerState config must contain `sources`.')

        self._source_configs = config['sources']

        max_active_sessions = config.get('maxActiveSessions', 128)

        max_queued_sessions = config.get('maxQueuedSessions', 1024)

        self._sessions = SessionRegistry(
            max_active_sessions, max_queued_sessions)

        self._session_timeout_seconds = config.get('sessionTimeoutSeconds', 30)

        self._max_vulns_to_serve = config.get('maxVulnsToServe', 128)

        return self

    
    def queue_session(self, platform):
        '''Create and queue a new session for a scanner running on a specific
        platform.
        Returns the ID of the newly-created session if there was room in the
        queue for it and the platform is supported, or else None.
        '''

        if not sources.is_supported(platform):
            return None

        session_id = generate_id()

        self._thread_safety_lock.acquire()

        did_queue = self._sessions.queue(session_id, platform)
        
        self._thread_safety_lock.release()

        if not did_queue:
            return None

        return session_id


    def retrieve_vulns(self, session_id):
        '''Retrieve vulnerabilities for a session.  If the session does not
        exist or is queued (i.e. not active), then None will be returned.
        Otherwise, this function returns a list of vulnerabilities.
        '''

        state = self._sessions.lookup(session_id)

        if state is None:
            return None

        vulns = self._cache.retrieve(
            state.scanning_platform,
            offset=state.vulns_read,
            limit=self._max_vulns_to_serve,
        )

        self._thread_safety_lock.acquire()

        if vulns is None:
            self._sessions.notify_activity(session_id)

            self._thread_safety_lock.release()

            return None

        self._sessions.notify_activity(session_id, read_vulns=len(vulns))

        self._thread_safety_lock.release()

        return vulns


    def update(self):
        '''Updates the server state to keep data moving. This function should
        be called every time a request is received, as it handles all of the
        work of ensuring that sessions are handled appropriately and that
        caches are kept fresh.
        '''

        self._terminate_timed_out_sessions()

        active = self._sessions.active()

        if len(active) == 0:
            self._thread_safety_lock.acquire()
            self._sessions.activate_sessions()
            self._initialize_caches()
            self._thread_safety_lock.release()

        active_platforms = list(set([
            self._sessions.lookup(session).scanning_platform
            for session in self._sessions.active()
        ]))

        for platform in active_platforms:
            cache_size = self._cache.size(platform)

            if cache_size == 0:
                continue

            complete = self._sessions.active(
                platform=platform, read_at_least=cache_size)
            
            active = self._sessions.active(platform=platform)

            if len(active) == len(complete) and len(complete) > 0:
                self._thread_safety_lock.acquire()        # LOCK ACQUIRE
                                                          # |
                vulns = self._load_vulns(platform)        # |
                                                          # |
                if len(vulns) > 0:                        # |
                    self._cache.cache(platform, vulns)    # |
                else:                                     # |
                    self._cache.remove_bucket(platform)   # |
                    for session in complete:              # |
                        self._sessions.terminate(session) # |
                                                          # |
                self._thread_safety_lock.release()        # LOCK RELEASE


    def _terminate_timed_out_sessions(self):
        timed_out = self._sessions.timed_out(self._session_timeout_seconds)

        for session_id in timed_out:
            self._sessions.terminate(session_id)


    def _initialize_caches(self):
        active_platforms = list(set([
            self._sessions.lookup(session).scanning_platform
            for session in self._sessions.active()
        ]))

        for platform in active_platforms:
            self._cache.remove_bucket(platform)

            source = sources.init(platform, self._source_configs)
            
            self._active_sources[platform] = source
            
            vulns = self._load_vulns(platform)

            self._cache.cache(platform, vulns)


    def _load_vulns(self, platform):
        vulns = []

        while len(vulns) < self._max_vulns_to_serve:
            vuln = next(self._active_sources[platform], None)

            if vuln is None:
                break

            vulns.append(vuln)

        return vulns
        

def generate_id(num_bytes=16):
    '''Generate a random string of hex.
    '''

    return urandom(num_bytes).hex()
