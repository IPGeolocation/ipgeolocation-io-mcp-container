FROM node:24-bookworm-slim@sha256:a5f4366e834695d5f363b920c104953a535d3a9864d1bdf74566a0ebe01daee5 AS build

WORKDIR /app
COPY package.json package-lock.json tsconfig.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm test && npm ci --omit=dev --ignore-scripts

FROM gcr.io/distroless/nodejs24-debian13:nonroot@sha256:55de7e48a8414e7aff825207c0b3c0f7db3b10133efc50d748560c27c9053be1 AS runtime

WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/package.json /app/package-lock.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY manifest.json server.json LICENSE README.md CHANGELOG.md SECURITY.md CONTRIBUTING.md RELEASING.md ./
COPY packaging/mpak/README.md ./packaging/mpak/README.md
USER 65532:65532
CMD ["/app/dist/cli.js"]
