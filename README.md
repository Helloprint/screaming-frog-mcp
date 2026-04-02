# screaming-frog-mcp — Helloprint Fork

Screaming Frog SEO Spider MCP server deployed via Elestio CI/CD on Hetzner.

This is Helloprint's fork of [bzsasson/screaming-frog-mcp](https://github.com/bzsasson/screaming-frog-mcp) with configuration for automated deployment to our Elestio infrastructure.

## Live Endpoint

```
https://screamingfrog.mcp.helloprint.com/sse
```

## What's Different From Upstream

This fork adds/modifies the following files for Elestio CI/CD deployment:

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage build with Java, Screaming Frog SEO Spider, Python, and MCP server |
| `elestio.yml` | Elestio CI/CD pipeline configuration (runtime, env vars, ports) |
| `entrypoint.sh` | Activates SF license from env vars at container startup |
| `patch_server.py` | Patches `sf_mcp.py` to add SSE transport support for container deployment |
| `README.md` | This file |

The `sf_mcp.py` is patched to add a `main()` function with SSE transport support. The upstream code only supports stdio transport. The patch adds host/port configuration via `mcp.settings` and disables DNS rebinding protection for container deployments.

## Connecting Your MCP Client

Add this to your MCP client config (Claude Desktop, Cursor, Cowork, etc.):

```json
{
  "mcpServers": {
    "screamingFrog": {
      "url": "https://screamingfrog.mcp.helloprint.com/sse"
    }
  }
}
```

Restart your client and the Screaming Frog tools will be available.

## Available Tools

| Tool | Description |
|------|-------------|
| `sf_check` | Verify Screaming Frog installation and license |
| `crawl_site` | Start a headless crawl of a URL |
| `crawl_status` | Check progress of a running crawl |
| `list_crawls` | List all stored crawls |
| `export_crawl` | Export crawl data to CSV |
| `read_crawl_data` | Read exported CSV data |
| `delete_crawl` | Delete a stored crawl |
| `storage_summary` | Show crawl storage usage |

## Deployment

Deployment is fully automated via Elestio CI/CD. Every push to `main` triggers a rebuild and redeploy.

### Environment Variables (set in Elestio dashboard)

| Variable | Value | Description |
|----------|-------|-------------|
| `MCP_TRANSPORT` | `sse` | Enables network SSE transport |
| `SF_CLI_PATH` | `/usr/bin/screamingfrogseospider` | Path to SF CLI inside container |
| `SF_LICENSE_USER` | *(secret)* | Screaming Frog license email |
| `SF_LICENSE_KEY` | *(secret)* | Screaming Frog license key |
| `FASTMCP_HOST` | `0.0.0.0` | Bind to all interfaces |
| `FASTMCP_PORT` | `8000` | Internal server port |

The license credentials are set in the Elestio dashboard and injected at runtime. They are **never committed to this repo**.

### VM Requirements

Screaming Frog is a Java application that requires significant resources for large crawls:

| Crawl Size | Recommended VM |
|------------|----------------|
| Up to 10K URLs | 2 vCPU, 4 GB RAM |
| 10K–100K URLs | 4 vCPU, 8–16 GB RAM |
| 100K+ URLs | 4+ vCPU, 16 GB RAM, 80 GB SSD |

The Helloprint deployment uses **4 vCPU, 16 GB RAM, 80 GB SSD** on Hetzner (~€25–35/mo).

### Port Mapping

```
Client → HTTPS:443 (Elestio nginx + SSL) → 172.17.0.1:3001 → container:8000 (MCP SSE)
```

## Syncing With Upstream

To pull in updates from the original repo:

1. Go to this fork on GitHub
2. Click **"Sync fork"** → **"Update branch"**
3. If there's a merge conflict in `sf_mcp.py`, resolve it by either:
   - Accepting upstream changes and re-running `python patch_server.py`
   - Manually keeping our patched `main()` function
4. Elestio auto-deploys the updated code

## Security

- The SSE endpoint has **no authentication** by default. Consider using Elestio's built-in basic auth (`isAuth: true` in `elestio.yml`) or Cloudflare Access to restrict access.
- Screaming Frog license credentials are injected via environment variables and never stored in the repo.
- The server validates URLs before crawling (no private IP ranges, no file:// protocol).
