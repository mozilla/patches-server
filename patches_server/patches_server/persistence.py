'''This module exports two abstract base classes called Persistent and Stateful.
Persistent is intended for wrappers around external mediums such as Redis to be
implemented such that they satisfy the interface described by Persistent.
Stateful is intended to be implemented by classes that need to manage state and
be able to persist and reload that state.
'''


from abc import ABC as AbstractBaseClass, abstractmethod


class Persistent(AbstractBaseClass):
    '''An abstract base class that defines what things can be persisted by a
    given medium that implements this class.
    '''

    def persist_state(self, state):
        '''The main interface of the Persistent class.  This method should be
        invoked to have a piece of state, represented as either a dictionary,
        a list or a primitive 
        '''

        if isinstance(state, dict):
            return self.persist_dict(state)
        elif isinstance(state, list) or isinstance(state, tuple):
            return self.persist_list(state)
        else:
            return self.persist_primitive(state)


    @abstractmethod
    def persist_primitive(self, primitive):
        '''Persist a primitive value to an external medium.
        Return None if no error occurs, otherwise return (do not raise!) an
        instance of Exception or a subclass of it.
        '''

        return None


    @abstractmethod
    def persist_list(self, list):
        '''Persist a list of values to an external medium.
        Return None if no error occurs, otherwise return (do not raise!) an
        instance of Exception or a subclass of it.
        '''

        return None


    @abstractmethod
    def persist_dict(self, dictionary):
        '''Persist a dictionary of values to an external medium.
        Return None if no error occurs, otherwise return (do not raise!) an
        instance of Exception or a subclass of it.
        '''

        return None


class Stateful(AbstractBaseClass):
    '''An abstract base class that defines things that can be reconstructed
    from a persistent medium implementing Persist.
    '''

    def set_persistence_medium(self, persist_impl):
        '''Store an object that implements Persist so we can use it later.
        '''

        self._persist_impl = persist_impl

    
    @property
    def persistent_medium(self):
        '''Retrieve the persistent medium.
        '''

        return self._persist_impl


    @abstractmethod
    def rebuild(self):
        '''Rebuild the state of the object from the persistent medium.
        This function should return a reconstructed self if successful,
        or else None.
        '''

        return self