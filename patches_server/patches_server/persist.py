'''Defines an abstract base class called State that is implemented
by datastructures that we need to persist and reload to and from
an external medium.
'''


from abc import ABC as AbstractBaseClass, abstractmethod as abstract


class State(AbstractBaseClass):
    '''An abstract base class whose inteface is intended to be implemented
    by any type that can have its state persisted to and rebuilt from an
    external medium, such as Redis.
    '''

    @abstract
    def persist(self, medium):
        '''Save the state of the object in the persistent medium.
        Return (do not raise!) a subclass of Exception if an error occurs,
        or else return None.
        '''

        return None


    @abstract
    def rebuild(self, medium):
        '''Reconstruct the state of the object from the data stored in an
        external medium.
        Return the object (self) if successful, or else return (do not
        raise!) an instance of a subclass of Exception if one does.
        '''

        return self
