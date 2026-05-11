# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/ ./packages/
RUN corepack enable && pnpm install --frozen-lockfile
RUN pnpm build  # Assumes build script in root or app package.json

# Production stage
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/packages/app/dist ./packages/app/dist  # Adjust if build outputs elsewhere
COPY --from=builder /app/packages/middleware ./packages/middleware
COPY --from=builder /app/node_modules ./node_modules
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --prod --frozen-lockfile
EXPOSE 3000  # Adjust to app's port from .env or package.json
CMD ["pnpm", "start"]  # Or "node server.js" based on scripts