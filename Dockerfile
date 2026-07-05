FROM steamcmd/steamcmd:ubuntu-22

# Prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

# Metadata Labels
LABEL maintainer="Terule <https://github.com/Terule>" \
      org.opencontainers.image.authors="Terule" \
      org.opencontainers.image.source="https://github.com/Terule/dst-dedicated-server" \
      org.opencontainers.image.description="Don't Starve Together Dedicated Server by Terule - Docker image with full environment variable configuration"

# Set locale
RUN apt-get update && apt-get install -y --no-install-recommends locales && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install additional dependencies for DST (32-bit and 64-bit runtimes)
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        lib32gcc-s1 \
        lib32stdc++6 \
        libcurl3-gnutls \
        libcurl3-gnutls:i386 \
        libstdc++6 \
        libsqlite3-0 \
        libsqlite3-0:i386 \
        libcurl4 \
        procps \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create steam user
RUN useradd -m steam

# Fix SteamCMD directories and symlinks to avoid verification loops
RUN mkdir -p /home/steam/.steam/sdk64 /home/steam/.steam/sdk32 /home/steam/.steam/root /home/steam/Steam/logs && \
    chown -R steam:steam /home/steam/.steam /home/steam/Steam

# Pre-create game and data directories with proper ownership
RUN mkdir -p /opt/dst-server /data && \
    chown -R steam:steam /opt/dst-server /data

VOLUME /data

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN sed -i -e 's/\r//g' /entrypoint.sh && chmod +x /entrypoint.sh

# Set final permissions
RUN chown -R steam:steam /home/steam /opt/dst-server /data

WORKDIR /home/steam

EXPOSE 10999/udp 11000/udp 10888/udp

# Health Check
HEALTHCHECK --interval=1m --timeout=10s --start-period=5m --retries=3 \
    CMD pgrep "dontstarve" > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
