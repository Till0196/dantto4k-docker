FROM ghcr.io/till0196/dmirakurun:base AS without-dnatto4k
WORKDIR /app

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        socat \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM ghcr.io/till0196/dantto4k AS dantto4k
FROM ghcr.io/till0196/dmirakurun:base AS with-dantto4k
WORKDIR /app

# Copy TSDuck deb files and Dantto4k binary from dantto4k image
COPY --from=dantto4k /opt/tsduck /opt/tsduck
COPY --from=dantto4k /usr/local/bin/dantto4k /usr/local/bin/dantto4k
RUN echo /opt/tsduck/lib > /etc/ld.so.conf.d/tsduck.conf && \
    ldconfig && \
    ln -sf /opt/tsduck/share/tsduck /usr/local/share/tsduck

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        make \
        gcc \
        g++ \
        pkg-config \
        pcscd \
        libpcsclite-dev \
        libccid \
        libedit2 \
        libcurl4 \
        libdvbv5-dev \
        pcsc-tools \
        dvb-tools \
        socat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 40772 40775 9229
