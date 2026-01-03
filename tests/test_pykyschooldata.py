"""
Tests for pykyschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pykyschooldata
    assert pykyschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pykyschooldata
    assert hasattr(pykyschooldata, 'fetch_enr')
    assert callable(pykyschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pykyschooldata
    assert hasattr(pykyschooldata, 'get_available_years')
    assert callable(pykyschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pykyschooldata
    assert hasattr(pykyschooldata, '__version__')
    assert isinstance(pykyschooldata.__version__, str)
