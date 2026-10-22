FROM node:22.23.4-alpine AS build

ENV NPM_CONFIG_UPDATE_NOTIFIER=false
ENV NPM_CONFIG_FUND=false

WORKDIR /app

COPY package*.json tsconfig.json ./
COPY src ./src

RUN npm ci --ignore-scripts && \
    npm run build && \
    npm prune --omit=dev --ignore-scripts

FROM node:22.23.4-alpine

WORKDIR /app

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./

ARG PG_VERSION='16'

RUN apk add --update --no-cache ca-certificates postgresql${PG_VERSION}-client && update-ca-certificates

CMD pg_isready --dbname=$BACKUP_DATABASE_URL && \
    pg_dump --version && \
    node dist/index.js
