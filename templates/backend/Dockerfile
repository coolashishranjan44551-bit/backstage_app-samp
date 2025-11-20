FROM node:18-bullseye as packages
WORKDIR /app

COPY . .
RUN yarn install --frozen-lockfile
RUN yarn tsc
RUN yarn build:backend

FROM node:18-bullseye
ENV NODE_ENV=production
WORKDIR /app

COPY --from=packages /app/packages/backend/dist ./packages/backend/dist
COPY --from=packages /app/app-config*.yaml ./
COPY --from=packages /app/package.json ./
COPY --from=packages /app/yarn.lock ./
COPY --from=packages /app/packages/backend/package.json ./packages/backend/

RUN addgroup --system backstage && adduser --system --ingroup backstage backstage
USER backstage
EXPOSE 7007
CMD ["node", "packages/backend/dist/index.js"]
