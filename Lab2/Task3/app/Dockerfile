# Stage 1: Build & Dependencies
FROM node:20-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# Stage 2: Final lightweight image
FROM node:20-alpine
WORKDIR /app

# Giam lo hong cho image runtime (phat hien boi Trivy trong Jenkins pipeline):
# - apk upgrade: lay ban va moi nhat cho cac goi Alpine (musl, zlib, ...)
# - Go npm/npx/yarn: runtime chi can `node`; npm di kem image goc chua goi
#   `tar` dinh lo hong CRITICAL (CVE-2026-59873)
RUN apk upgrade --no-cache && \
    rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx \
           /opt/yarn* /usr/local/bin/yarn /usr/local/bin/yarnpkg

# Tao non-root user cho bao mat container (Trivy se danh gia cao diem nay)
USER node

# Copy dependencies tu stage 1
COPY --chown=node:node --from=dependencies /app/node_modules ./node_modules
COPY --chown=node:node src/ ./src
COPY --chown=node:node package*.json ./

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "src/server.js"]
