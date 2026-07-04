FROM debian:12-slim

# Prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

# Set locale
RUN apt-get update && apt-get install -y --no-install-recommends locales && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        lib32gcc-s1 \
        lib32stdc++6 \
        libcurl4-gnutls-dev:i386 \
        libstdc++6 \
        libsqlite3-0 \
        libsqlite3-0:i386 \
        libcurl4 \
        procps \
        && \
    rm -rf /var/lib/apt/lists/*

# Create steam user
RUN groupadd -g 1000 steam && \
    useradd -u 1000 -g steam -m steam

# Download and install SteamCMD
RUN mkdir -p /opt/steamcmd && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /opt/steamcmd && \
    chown -R steam:steam /opt/steamcmd

# Link steamcmd to standard path and pre-create DST directory with proper ownership
RUN ln -s /opt/steamcmd/steamcmd.sh /usr/games/steamcmd && \
    mkdir -p /opt/dst-server && \
    chown -R steam:steam /opt/dst-server

# Install DST Server
USER steam
RUN /usr/games/steamcmd +force_install_dir /opt/dst-server +login anonymous +app_update 343050 validate +quit

# Switch back to root to set up script and directory
USER root

# Create volume dir and set permissions
RUN mkdir -p /data && chown -R steam:steam /data
VOLUME /data

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN sed -i -e 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh && chown steam:steam /entrypoint.sh

USER steam
WORKDIR /opt/dst-server

EXPOSE 10999/udp 11000/udp 10888/udp

ENTRYPOINT ["/entrypoint.sh"]
