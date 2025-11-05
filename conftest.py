# conftest.py
import warnings

import pytest


def pytest_sessionfinish(session, exitstatus):
    if exitstatus == pytest.ExitCode.NO_TESTS_COLLECTED:
        warnings.warn("====== NO TESTS COLLECTED. But tests should be implemented. ======", stacklevel=2)
        session.exitstatus = pytest.ExitCode.OK
