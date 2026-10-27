FROM node:24.22.1-alpine3.24@sha256:06d7adf3e0ef61a13f1d28682726366f97a15aa1888c934d3ecec86c33918b53 AS build

WORKDIR /app
COPY package.json package-lock.json tsconfig.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN --network=none npm test
RUN npm ci --omit=dev --ignore-scripts

FROM node:24.22.1-alpine3.24@sha256:06d7adf3e0ef61a13f1d28682726366f97a15aa1888c934d3ecec86c33918b53 AS runtime

WORKDIR /app
ENV NODE_ENV=production
# Remove package installers and the shell to preserve the minimal runtime contract.
RUN apk add --no-network ca-certificates-bundle alpine-baselayout-data \
    && rm -rf /usr/local/lib/node_modules/npm /opt/yarn* \
        /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/yarn /usr/local/bin/yarnpkg \
    && apk del --no-cache --no-scripts alpine-baselayout busybox busybox-binsh ssl_client apk-tools
COPY --from=build /app/package.json /app/package-lock.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY manifest.json server.json LICENSE README.md CHANGELOG.md SECURITY.md CONTRIBUTING.md RELEASING.md ./
COPY packaging/mpak/README.md ./packaging/mpak/README.md
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/node"]
CMD ["/app/dist/cli.js"]
