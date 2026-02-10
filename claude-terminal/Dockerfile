ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set npm global path to a predictable location
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm
ENV PATH="/usr/local/share/npm/bin:$PATH"

# Install system packages and development tools
RUN apk add --no-cache \
    bash \
    curl \
    nano \
    nodejs \
    npm \
    python3 \
    py3-pip \
    py3-requests \
    py3-aiohttp \
    py3-yaml \
    py3-beautifulsoup4 \
    git \
    vim \
    wget \
    jq \
    tree \
    yq

# Install Claude Code CLI using NPM with explicit prefix
RUN mkdir -p /usr/local/share/npm && \
    npm install -g @anthropic-ai/claude-code

# Create symlink for convenience
RUN ln -sf /usr/local/share/npm/bin/claude /usr/local/bin/claude

# Create directory for Claude configuration and set working directory
RUN mkdir -p /config/claude-config
WORKDIR /config

# Copy startup script and modular scripts
COPY run.sh /run.sh
COPY scripts/ /opt/scripts/
RUN chmod +x /run.sh \
    && chmod +x /opt/scripts/*.sh

# Use exec form for better signal handling
CMD ["/run.sh"]