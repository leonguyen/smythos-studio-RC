# Dockerfile.render - Optimized for Render.com deployment
FROM node:22-alpine

# Install necessary packages including MySQL client for Prisma
RUN apk add --no-cache \
    openssl \
    openssl-dev \
    libc6-compat \
    ca-certificates \
    curl \
    mysql-client \
    mysql-dev

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY tsconfig.json ./

# Install pnpm
RUN npm install -g pnpm@10.12.2

# Copy source code
COPY packages/ ./packages/

# Install dependencies and build
RUN pnpm install --frozen-lockfile && \
    pnpm run build && \
    pnpm store prune

# Generate Prisma client for Alpine
WORKDIR /app/packages/middleware
RUN pnpm run prisma:generate

# Create data directory
RUN mkdir -p /home/node/smythos-data/.smyth/models && \
    echo '{}' > /home/node/smythos-data/vault.json && \
    chown -R node:node /home/node

# Switch to node user
USER node

# Set environment
ENV NODE_ENV=production
ENV DOCKER_CONTAINER=true
ENV HOST=0.0.0.0

# Expose the required ports (Render uses PORT env var)
EXPOSE 5050 5053

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:5050/health || exit 1

# Start script that handles both services
COPY --chown=node:node render-start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
