FROM python:3.12-slim

LABEL org.opencontainers.image.title="MovieBox API Pro"
LABEL org.opencontainers.image.description="Pure REST API wrapper for moviebox.ph — zero scraping"
LABEL org.opencontainers.image.authors="Faisal <https://github.com/faisaljs>"
LABEL org.opencontainers.image.source="https://github.com/faisaljs/Moviebox-API"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/faisaljs/Moviebox-API"

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8000 \
    CATALOG_DB=/data/catalog.db

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ─── Copy kode (eksplisit, urutan dari yang paling jarang berubah) ───
COPY routes/ ./routes/
COPY static/ ./static/
COPY *.py ./

# ─── Verifikasi saat build: gagal cepat jika routes/ atau main.py hilang ───
# Jika langkah ini gagal, Anda akan lihat pesan jelas di log build,
# bukan traceback Uvicorn yang membingungkan.
RUN test -d /app/routes && \
    test -f /app/routes/__init__.py && \
    test -f /app/routes/router.py 2>/dev/null || test -f /app/routes/__init__.py && \
    test -f /app/main.py && \
    python -c "import routes, main; print('IMPORT OK — routes and main load fine')"

RUN mkdir -p /data

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -fsS http://localhost:${PORT}/health || exit 1

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT} --timeout-keep-alive 75"]
