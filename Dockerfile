FROM node:24.22.1-alpine3.24@sha256:06d7adf3e0ef61a13f1d28682726366f97a15aa1888c934d3ecec86c33918b53 AS target-base

# Compile and test on the builder CPU when packaging more than one architecture.
FROM --platform=$BUILDPLATFORM node:24.22.1-alpine3.24@sha256:06d7adf3e0ef61a13f1d28682726366f97a15aa1888c934d3ecec86c33918b53 AS build

WORKDIR /app
COPY package.json package-lock.json tsconfig.json ./
RUN npm ci --ignore-scripts
RUN apk add --no-cache bash unzip
COPY . .
RUN --network=none npm test

FROM target-base AS dependencies
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts

FROM target-base AS runtime

WORKDIR /app
ENV NODE_ENV=production
# Keep the node account at the UID used by existing container deployments.
RUN sed -i 's/^node:x:1000:1000:/node:x:65532:65532:/' /etc/passwd \
    && sed -i 's/^node:x:1000:/node:x:65532:/' /etc/group \
    && chown 65532:65532 /home/node \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/corepack /opt/yarn* \
        /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
        /usr/local/bin/yarn /usr/local/bin/yarnpkg /usr/local/bin/pnpm /usr/local/bin/pnpx \
    && apk add --no-network --no-scripts ca-certificates-bundle alpine-baselayout-data \
    && apk del --no-network --no-scripts alpine-baselayout busybox busybox-binsh ssl_client apk-tools \
    && node -e "const fs = require('node:fs'); \
        for (const dir of ['/bin', '/sbin', '/usr/bin', '/usr/sbin']) { \
            for (const entry of fs.readdirSync(dir, { withFileTypes: true })) { \
                const file = dir + '/' + entry.name; \
                if (entry.isSymbolicLink() && fs.readlinkSync(file) === '/bin/busybox') fs.unlinkSync(file); \
            } \
        } \
        fs.mkdirSync('/opt', { recursive: true }); \
        for (const dir of ['/tmp', '/var/tmp']) { fs.mkdirSync(dir, { recursive: true }); fs.chmodSync(dir, 0o1777); }"
COPY --from=build /app/package.json /app/package-lock.json ./
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY manifest.json server.json LICENSE README.md CHANGELOG.md SECURITY.md CONTRIBUTING.md RELEASING.md REFERENCE.md ./
COPY packaging/mpak/README.md ./packaging/mpak/README.md
COPY packaging/kiro/ ./packaging/kiro/
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/node"]
CMD ["/app/dist/cli.js"]
