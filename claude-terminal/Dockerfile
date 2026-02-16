ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set npm global path to a predictable location
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm
ENV PATH="/usr/local/share/npm/bin:$PATH"

# Install system packages (minimized for security)
RUN apk add --no-cache \
    bash \
    curl \
    nano \
    nodejs \
    npm \
    python3 \
    py3-pip \
    git \
    jq

# Install Claude Code CLI using NPM with explicit prefix
RUN mkdir -p /usr/local/share/npm && \
    npm install -g @anthropic-ai/claude-code

# Create symlink for convenience
RUN ln -sf /usr/local/share/npm/bin/claude /usr/local/bin/claude

WORKDIR /data

# Copy startup script and modular scripts
COPY run.sh /run.sh
COPY scripts/ /opt/scripts/
RUN chmod +x /run.sh \
    && chmod +x /opt/scripts/*.sh

# Use exec form for better signal handling
CMD ["/run.sh"]
