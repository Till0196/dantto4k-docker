ARG ARCH=
FROM ${ARCH}node:22.14.0-bookworm AS build
WORKDIR /app
ENV DOCKER=YES NODE_ENV=production
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl && \
    curl -sSL https://github.com/otya128/MMirakurun/archive/refs/tags/3.9.0-rc.4-4K.tar.gz | tar -xz --strip-component=1 && \
    npm ci --include=dev && \
    npx tslint --project . --fix && \
    npm run build && \
    npm ci --omit=dev

RUN mkdir -p /tmp/recdvb && \
    cd /tmp/recdvb && \
    curl -sSL https://github.com/otya128/recdvb/tarball/master | tar -xz --strip-component=1 && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local && \
    make -j$(( $(grep cpu.cores /proc/cpuinfo | sort -u | sed 's/[^0-9]//g') + 1 )) && \
    make install

FROM ${ARCH}node:22.14.0-bookworm-slim
WORKDIR /app
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
        libdvbv5-dev \
        pcsc-tools \
        dvb-tools \
        socat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY --from=build /app /app
COPY --from=build /usr/local/bin/recdvb /usr/local/bin/recdvb
CMD ["./docker/container-init.sh"]
EXPOSE 40772 9229