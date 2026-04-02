FROM python:3.13-slim-bookworm

# ---- System deps: Java (for Screaming Frog) + misc ----
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget \
        gnupg2 \
        ca-certificates \
        fontconfig \
        libfreetype6 \
        libx11-6 \
        libxext6 \
        libxrender1 \
        libxtst6 \
        libxi6 \
        xdg-utils \
        default-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# ---- Install Screaming Frog SEO Spider ----
# Download and install the latest .deb package
RUN wget -q "https://download.screamingfrog.co.uk/products/seo-spider/screamingfrogseospider_latest_all.deb" \
        -O /tmp/sf.deb \
    && dpkg -i /tmp/sf.deb || apt-get install -f -y --no-install-recommends \
    && rm /tmp/sf.deb \
    && rm -rf /var/lib/apt/lists/*

# ---- Screaming Frog license activation ----
# The license is injected via environment variables at runtime.
# SF stores its config in ~/.ScreamingFrogSEOSpider/
# We create the directory structure so the entrypoint can write the license file.
RUN mkdir -p /root/.ScreamingFrogSEOSpider

# ---- Python app ----
WORKDIR /app

COPY pyproject.toml README.md ./
COPY sf_mcp.py ./
COPY src/ ./src/

# Install the project and dependencies
RUN pip install --no-cache-dir -e ".[dev]" 2>/dev/null || pip install --no-cache-dir -e . \
    && pip install --no-cache-dir "mcp[cli]>=1.26.0" python-dotenv

# ---- Environment defaults ----
ENV SF_CLI_PATH="/usr/bin/screamingfrogseospider" \
    MCP_TRANSPORT="sse" \
    FASTMCP_HOST="0.0.0.0" \
    FASTMCP_PORT="8000"

# ---- Entrypoint ----
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "sf_mcp.py"]
