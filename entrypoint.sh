#!/bin/bash
set -e

# Activate Screaming Frog license if credentials are provided
if [ -n "$SF_LICENSE_USER" ] && [ -n "$SF_LICENSE_KEY" ]; then
    echo "Activating Screaming Frog license..."
    mkdir -p /root/.ScreamingFrogSEOSpider
    cat > /root/.ScreamingFrogSEOSpider/licence.txt <<EOF
${SF_LICENSE_USER}
${SF_LICENSE_KEY}
EOF
    echo "License file written."
else
    echo "WARNING: SF_LICENSE_USER and SF_LICENSE_KEY not set. Screaming Frog will run in free mode (500 URL limit)."
fi

# Verify Screaming Frog is installed
if [ -x "$SF_CLI_PATH" ]; then
    echo "Screaming Frog CLI found at: $SF_CLI_PATH"
else
    echo "WARNING: Screaming Frog CLI not found at: $SF_CLI_PATH"
fi

# Run the MCP server
exec "$@"
