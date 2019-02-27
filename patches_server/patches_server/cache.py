'''A simple in-memory cache store.
'''

from dataclasses import dataclass, field
from typing import Any, Dict, List


@dataclass
class Cache:
    '''An in-memory cache that buckets values in relation to identifiers.
    Each bucket is treated as an infinitely-growing (until removed) collection.

    Definitions:
    * "bucket" refers to an identifier that maps to a collection of cached
    values
    * "full set" refers to the (imaginary) collection of all values that have
    been cached
    * "active set" refers to the collection of values that are currently stored
    in memory
    * "inactive set" refers to the collection of values that had been cached
    but are no longer in memory

    Readers of the cache are expected to track the number of values they have
    read.  When this tracked value is provided as an offset to `retrieve`,
    the offset is treated as an offset into the full set.

    Corollary 1:
    If an offset greater than the size of the full set is provided to
    `retrieve`, an empty list of values will be returned, indiciating that the
    caller has reached the end of the full set.

    Corollary 2:
    If an offset is provided to `retrieve` that would require a read to start
    in the inactive set, all values in the active set will be returned.
    '''

    buckets: Dict[str, List[Any]] = field(default_factory=dict)
    _total_item_counts: Dict[str, int] = field(default_factory=dict)

    def remove_bucket(self, bucket):
        '''Remove a bucket and all associated items from the cache.
        '''

        if bucket not in self.buckets:
            return self

        self.buckets.pop(bucket)
        self._total_item_counts.pop(bucket)

        return self


    def size(self, bucket):
        '''Return the number of items in a provided bucket.
        If the bucket does not exist, 0 will be returned.
        '''

        return self._total_item_counts.get(bucket, 0)


    def cache(self, bucket, items):
        '''Store items in the cache under a specific bucket.
        If the bucket does not exist, it will be created.
        If the bucket does exist, any presently cached items will be replaced.
        '''

        self.buckets[bucket] = items

        self._total_item_counts[bucket] =\
            self._total_item_counts.get(bucket, 0) + len(items)

        return self


    def retrieve(self, bucket, offset=0, limit=None):
        '''Retrieve items cached under a specific bucket.
        If the bucket specified does not exist, None will be returned.
        '''

        if bucket not in self.buckets:
            return None

        if offset > self._total_item_counts[bucket]:
            return []
        
        items = self.buckets[bucket]

        start_index = abs(self._total_item_counts[bucket] - len(items) - offset)
        
        if offset <= self._total_item_counts[bucket] - len(items):
            start_index = 0

        if limit is None or limit > len(items):
            return items[start_index:]

        end_index = start_index + limit

        return items[ start_index : end_index ]