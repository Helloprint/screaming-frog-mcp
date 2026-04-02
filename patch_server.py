"""
Run this script after cloning/syncing with upstream to patch sf_mcp.py
for Elestio deployment compatibility.

Changes:
1. Replaces the bare `mcp.run()` call with a main() function that supports
   both stdio and SSE transport modes.
2. Configures host/port via mcp.settings (mcp SDK v1.26+ API).
3. Disables DNS rebinding protection for container deployments.

Usage: python patch_server.py
"""
import re

with open("sf_mcp.py", "r") as f:
    content = f.read()

# Check if already patched
if "def main():" in content and "mcp.settings.host" in content:
    print("Already patched — no changes needed.")
    exit(0)

# The upstream code ends with:
#   if __name__ == "__main__":
#       mcp.run()
#
# We replace this with a main() function that supports SSE transport.

old_block = 'if __name__ == "__main__":\n    mcp.run()'

new_block = '''def main():
    """Entry point for the MCP server. Supports stdio (default) and SSE transports."""
    import os
    transport = os.environ.get("MCP_TRANSPORT", "stdio").lower()

    if transport == "stdio":
        mcp.run(transport="stdio")
    elif transport in {"sse", "http"}:
        mcp.settings.host = "0.0.0.0"
        mcp.settings.port = 8000
        mcp.settings.transport_security.enable_dns_rebinding_protection = False
        mcp.run(transport="sse")
    else:
        raise ValueError(
            f"Unknown MCP_TRANSPORT '{transport}'. "
            "Use 'stdio' (default) or 'sse'."
        )


if __name__ == "__main__":
    main()'''

patched = content.replace(old_block, new_block)

if patched == content:
    print("WARNING: Could not find the expected code pattern. Manual patching may be needed.")
    print("Expected to find:")
    print(repr(old_block))
else:
    with open("sf_mcp.py", "w") as f:
        f.write(patched)
    print("Patched sf_mcp.py successfully.")
    print("  - Added main() with stdio/SSE transport support")
    print("  - Configured mcp.settings for container deployment")
    print("  - Disabled DNS rebinding protection")
