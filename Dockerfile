FROM node:24.16-alpine AS base
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@11 --activate

# install dependencies
FROM base AS dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --ignore-scripts

# build app
FROM base AS builder
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/package.json ./package.json
COPY --from=dependencies /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY tsconfig.json nest-cli.json ./
COPY src ./src
RUN pnpm run build
RUN pnpm prune --prod 

# final build for production
FROM node:24.16-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000
CMD ["node", "dist/main.js"]