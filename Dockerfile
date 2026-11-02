FROM python:3.12-slim

LABEL org.opencontainers.image.title="MovieBox API Pro"
LABEL org.opencontainers.image.description="Pure REST API wrapper for moviebox.ph — zero scraping"
LABEL org.opencontainers.image.authors="Faisal <https://github.com/faisaljs>"
LABEL org.opencontainers.image.source="https://github.com/faisaljs/Moviebox-API"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/faisaljs/Moviebox-API"

WORKDIR /app

# Defaults — selaras dengan volume /data di Hostless, dan port yang dibaca config.py
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8000 \
    CATALOG_DB=/data/catalog.db

# Install curl untuk healthcheck (lebih ringan dari spawn Python httpx setiap probe)
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Install deps dulu (layer cache: hanya rebuild jika requirements berubah)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ✅ FIX: copy SELURUH proyek — ini yang menyalin folder routes/ dan static/
# Versi lama `COPY *.py ./` hanya menyalin file .py di root, bukan folder.
COPY . .

# Siapkan mount point volume /data (untuk catalog.db persisten di Hostless)
RUN mkdir -p /data

EXPOSE 8000

# Healthcheck pakai curl (shell form agar ${PORT} ter-expand)
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -fsS http://localhost:${PORT}/health || exit 1

# ✅ FIX: shell form agar $PORT (dari Hostless) ter-expand,
# dan --timeout-keep-alive 75 mencegah 502 saat proxy streaming
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT} --timeout-keep-alive 75"]
