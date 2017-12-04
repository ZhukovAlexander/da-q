from setuptools import setup


setup(
    name='daq',
    description='MPMC Queue on top of PostgreSQL',
    keywords='python asyncio queue postgresql',
    use_scm_version=True,
    setup_requires=['setuptools_scm'],
    py_modules=['daq'],
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3',
        'Topic :: Software Development :: Libraries :: Python Modules',
    ],
)