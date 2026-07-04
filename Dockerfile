FROM steamcmd/steamcmd:ubuntu-22

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

# Install dependencies (DST 64-bit and steamcmd 32-bit runtimes)
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

# Create steam user (Note: ubuntu base image does not have steam user by default)
RUN useradd -m steam

# Pre-create DST server directory with proper ownership
RUN mkdir -p /opt/dst-server && \
    chown -R steam:steam /opt/dst-server

# Install DST Server
USER steam
RUN steamcmd +force_install_dir /opt/dst-server +login anonymous +app_update 343050 validate +quit

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
