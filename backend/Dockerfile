FROM python:3.13-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/opt/venv/bin:${PATH}"

WORKDIR /app

RUN python -m venv /opt/venv

COPY backend/requirements.txt backend/requirements.txt
RUN pip install --upgrade pip && pip install -r backend/requirements.txt

COPY backend backend
COPY database database

RUN adduser --disabled-password --gecos "" --home /home/fittrack fittrack \
    && chown -R fittrack:fittrack /app /opt/venv

USER fittrack
WORKDIR /app/backend

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5)"

CMD ["sh", "scripts/entrypoint.sh"]
