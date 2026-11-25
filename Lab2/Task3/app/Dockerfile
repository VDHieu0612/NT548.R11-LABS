# Stage 1: Build & Dependencies
FROM node:20-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Final lightweight image
FROM node:20-alpine
WORKDIR /app

# Tao non-root user cho bao mat container (Trivy se danh gia cao diem nay)
USER node

# Copy dependencies tu stage 1
COPY --chown=node:node --from=dependencies /app/node_modules ./node_modules
COPY --chown=node:node src/ ./src
COPY --chown=node:node package*.json ./

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["npm", "start"]
