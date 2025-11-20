# Multi-stage build that assembles the Backstage demo app into a production image
# and is tuned for AKS (non-root runtime, minimal layers).

# 1) Builder: clone the Backstage demo and build it
FROM node:18-bullseye AS builder
ARG DEMO_REPO=https://github.com/backstage/demo.git
ARG DEMO_REF=main
ENV APP_DIR=/app

# Install build tooling
RUN apt-get update && apt-get install -y --no-install-recommends git python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

WORKDIR ${APP_DIR}
RUN git clone --depth=1 --branch ${DEMO_REF} ${DEMO_REPO} .

# Install and build the Backstage app
RUN yarn install --frozen-lockfile
RUN yarn tsc
RUN yarn build:backend --config app-config.yaml --config app-config.production.yaml

# 2) Runtime: copy the built backend bundle and run as a non-root user
FROM node:18-bullseye-slim
ENV APP_DIR=/app
ENV NODE_ENV=production

# Create non-root user
RUN useradd -r -u 10001 backstage && mkdir -p ${APP_DIR} && chown backstage:backstage ${APP_DIR}
WORKDIR ${APP_DIR}

# Copy built artifacts
COPY --from=builder /app/packages/backend/dist ./packages/backend/dist
COPY --from=builder /app/packages/backend/package.json ./packages/backend/package.json
COPY --from=builder /app/yarn.lock ./yarn.lock
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/app-config*.yaml ./

# Install only backend production dependencies
RUN yarn workspaces focus --production @backstage/backend

USER backstage
EXPOSE 7007
CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
