# Tests

This directory contains FitTrack test suites.

Recommended layout:

```text
tests/
  backend/
    unit/
    integration/
  mobile/
    widget/
    integration/
  e2e/
```

Backend tests should cover FastAPI endpoints, services, repositories, RBAC, payments, notifications, and analytics.

Mobile tests should cover authentication screens, workout creation, progress tracking, Premium purchase flow, and localization.
