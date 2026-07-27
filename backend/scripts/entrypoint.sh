#!/usr/bin/env sh
set -eu

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  alembic -c alembic.ini upgrade head
fi

exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
