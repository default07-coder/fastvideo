# ============================================================
#  FastVideo — Docker image (ZIP-based)
#  يستخرج كود التطبيق من FastVideo-deploy.zip داخل الصورة
# ============================================================
FROM node:22-bookworm-slim

# --- أدوات النظام ---
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-venv ffmpeg ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*

# --- yt-dlp ---
RUN python3 -m venv /opt/yt \
 && /opt/yt/bin/pip install --no-cache-dir --upgrade yt-dlp \
 && ln -sf /opt/yt/bin/yt-dlp /usr/local/bin/yt-dlp

ENV PATH="/opt/yt/bin:${PATH}" \
    YTDLP_PYTHON="/opt/yt/bin/python" \
    FFMPEG_PATH="/usr/bin/ffmpeg" \
    NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0

WORKDIR /app

# --- فك ضغط كود التطبيق ---
COPY FastVideo-deploy.zip /tmp/app.zip
RUN unzip -q /tmp/app.zip -d /app \
 && rm -f /tmp/app.zip

# --- تثبيت الحزم ---
RUN npm ci --omit=dev --no-audit --no-fund

# --- الصلاحيات ---
RUN mkdir -p /app/data/downloads && chown -R node:node /app
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=6s --start-period=25s --retries=3 \
  CMD curl -fsS http://localhost:3000/api/health || exit 1

CMD ["node", "server/index.js"]
