'''A simple in-memory cache store.
'''

from dataclasses import dataclass, field
from typing import Any, Dict, List


@dataclass
class Cache:
    '''An in-memory bucketed cache store.
    '''

    buckets: Dict[str, List[Any]] = field(default_factory=dict)

    def remove_bucket(self, bucket):
        '''Remove a bucket and all associated items from the cache.
        '''

        if bucket not in self.buckets:
            return self

        self.buckets.pop(bucket)

        return self


    def size(self, bucket):
        '''Return the number of items in a provided bucket.
        If the bucket does not exist, 0 will be returned.
        '''

        items = self.buckets.get(bucket, [])

        return len(items)


    def cache(self, bucket, items):
        '''Store items in the cache under a specific bucket.
        If the bucket does not exist, it will be created.
        If the bucket does exist, any presently cached items will be replaced.
        '''

        self.buckets[bucket] = items

        return self


    def retrieve(self, bucket, offset=0, limit=None):
        '''Retrieve items cached under a specific bucket.
        If the bucket specified does not exist, None will be returned.
        '''

        if bucket not in self.buckets:
            return None

        items = self.buckets[bucket]

        if limit is None or limit > len(items):
            return items[offset:]

        end_index = offset + limit

        return items[ offset : end_index ]