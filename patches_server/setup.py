#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""The setup script."""

from setuptools import setup, find_packages

with open('README.md') as readme_file:
    readme = readme_file.read()

with open('HISTORY.md') as history_file:
    history = history_file.read()

requirements = [ ]

setup_requirements = ['pytest-runner', ]

test_requirements = ['pytest', ]

setup(
    author="Emma Rose",
    author_email='emrose@mozilla.com',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: Mozilla Public License 2.0',
        'Natural Language :: English',
        "Programming Language :: Python :: 2",
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
    ],
    description="A caching vulnerability server bringing together sources such as CoreOS' Clair",
    install_requires=requirements,
    license="Mozilla Public License 2.0",
    long_description=readme + '\n\n' + history,
    include_package_data=True,
    keywords='patches_server',
    name='patches_server',
    packages=find_packages(include=['patches_server']),
    setup_requires=setup_requirements,
    test_suite='tests',
    tests_require=test_requirements,
    url='https://github.com/mozilla/patches_server',
    version='1.0.0',
    zip_safe=False,
)
