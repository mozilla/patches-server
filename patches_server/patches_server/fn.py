'''Functional utilities.
'''

def matches(value, against_spec):
    '''Assert that a particular value has a specific shape.

    `against_spec` should be one of either:

    1. A primitive type, such as `int`, `str`, or `float`,
    2. A list or tuple containing one or more primitive types or
    3. A dictionary mapping expected keys to either of these three values.

    In the case that `against_spec` is a list or tuple with one value, it will
    be asserted that _all_ values in `value` have the type in the spec.

    In the case that `against_spec` is a list or tuple with more than one value,
    it will be asserted that each `value` has the corresponding spec type.

    In the case that `against_spec` is a dictionary, it will be asserted that
    `value` contains all of the keys in the spec.
    '''

    if not isinstance(value, spec):
        return False

    if spec == list and len(spec) == 1:
        return all([ matches(v, spec[0]) for v in value ])
    
    if spec in (list, tuple) and len(spec) > 1:
        return len(value) == len(spec) and all([
            matches(value[i], spec[i])
            for i in range(0, len(spec))
        ])

    if isinstance(spec, dict):
        return all([
            key in value and matches(value[key], _type)
            for key, _type in spec
        ])

    return False