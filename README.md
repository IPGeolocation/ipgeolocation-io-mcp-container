# IPGeolocation.io MCP container

The official IPGeolocation.io MCP server provides 17 tools for accurate IP geolocation, company information, ASN and network data, IP security (VPN, proxy, Tor, bot, hosting and spam detection), abuse contacts, time zones, astronomy, currency data and user-agent parsing.

This repository packages the [2.0.2 release](https://github.com/IPGeolocation/ipgeolocation-io-mcp/releases/tag/v2.0.2) for Linux amd64 and arm64. The manual workflow tests and builds the release source from commit `7cabc5016a500b617217aa7af11b29cc19d6c643` with Node.js 24.22.1 on a pinned Alpine 3.24 base. It removes BusyBox and package installers from the runtime while retaining UID 65532, stdio startup and HTTPS support. Native amd64 and arm64 checks run before publication. It scans both architectures, publishes an SBOM and build provenance, and signs the image digest. It refuses to overwrite the 2.0.2 container tag.

## Run the container

Set `IPGEOLOCATION_API_KEY` in the private environment that launches your MCP client:

```bash
docker run --rm -i --env IPGEOLOCATION_API_KEY ghcr.io/ipgeolocation/ipgeolocation-io-mcp:2.0.2
```

ToolHive can run the same image:

```bash
thv run --env NODE_USE_ENV_PROXY=1 ghcr.io/ipgeolocation/ipgeolocation-io-mcp:2.0.2
```

The proxy setting lets Node.js use ToolHive’s isolated network.

Use ToolHive’s secret provider to supply `IPGEOLOCATION_API_KEY` for authenticated lookups. `get_my_ip` works without a key or credits. Cached-result retrieval reads the running server’s memory and uses the original lookup’s key. Available data depends on your IPGeolocation.io plan.

The container runs as an unprivileged user over stdio. Its runtime contains no shell or package manager. It needs outbound HTTPS to `api.ipgeolocation.io` for API lookups and requires no host-directory mounts. It contains no API key. See the [server documentation](https://github.com/IPGeolocation/ipgeolocation-io-mcp#readme) for tool inputs and client setup.

[Security policy](https://github.com/IPGeolocation/ipgeolocation-io-mcp/blob/main/SECURITY.md) · [Privacy policy](https://ipgeolocation.io/privacy.html) · [Support](mailto:support@ipgeolocation.io)

License: MIT. Source and releases: [IPGeolocation/ipgeolocation-io-mcp](https://github.com/IPGeolocation/ipgeolocation-io-mcp).
