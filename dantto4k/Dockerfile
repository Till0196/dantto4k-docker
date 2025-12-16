FROM debian:bookworm AS base

WORKDIR /app
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    curl \
    gpg \
    lsb-release \
    software-properties-common && \
    curl -fsSL https://apt.llvm.org/llvm.sh | bash && \
    # Set up alternatives for clang/clang++ without version suffix
    CLANG_VERSION=$(ls /usr/bin/clang-* | grep -o '[0-9]\+' | head -1) && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION} 100 && \
    update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-${CLANG_VERSION} 100 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM base AS tsduck-build
# renovate: datasource=github-releases depName=tsduck/tsduck
ARG TSDUCK_VERSION=3.41-4299

WORKDIR /app
RUN apt-get update && \
    apt-get install -y \
    locales \
    sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    echo "LANG=en_US.UTF-8" > /etc/default/locale

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN mkdir tsduck && \
    cd tsduck && \
    curl -sSL https://github.com/tsduck/tsduck/tarball/v${TSDUCK_VERSION} | tar -xz --strip-component=1 && \
    # fix NODOC option
    sed -i '/gem install/d' scripts/install-prerequisites.sh && \
    ./scripts/install-prerequisites.sh NORIST=1 NOSRT=1 NOVATEK=1 NOJAVA=1 NODOXYGEN=1 NODOC=1 && \
    mkdir -p /opt/tsduck && \
    make -j$(( $(grep cpu.cores /proc/cpuinfo | sort -u | sed 's/[^0-9]//g') + 1 )) \
        LLVM=1 \
        NODEKTEC=1 NOHIDES=1 NOVATEK=1 NORIST=1 NOSRT=1 NOJAVA=1 NODOXYGEN=1 NODOC=1 NOTEST=1 NOGITHUB=1 \
        SYSPREFIX=/opt/tsduck \
        default && \
    make LLVM=1 \
        NODEKTEC=1 NOHIDES=1 NOVATEK=1 NORIST=1 NOSRT=1 NOJAVA=1 NODOXYGEN=1 NODOC=1 NOTEST=1 NOGITHUB=1 \
        SYSPREFIX=/opt/tsduck \
        install

FROM base AS dantto4k-build
# renovate: datasource=github-releases depName=nekohkr/dantto4k
ARG DANTTO4K_VERSION=1.0.0-rc9

WORKDIR /app

# Install dantto4k dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    libssl-dev \
    libedit-dev \
    zlib1g-dev \
    pcscd \
    libpcsclite-dev \
    libcurl4-openssl-dev \
    make \
    pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy TSDuck files
COPY --from=tsduck-build /opt/tsduck /opt/tsduck
RUN echo /opt/tsduck/lib > /etc/ld.so.conf.d/tsduck.conf && \
    ldconfig

# Build Dantto4k
RUN git clone --depth 1 --branch v${DANTTO4K_VERSION} --recurse-submodules https://github.com/nekohkr/dantto4k.git /tmp/dantto4k && \
    cd /tmp/dantto4k && \
    # ARMでは-maesと-msse4.1を除外、x86専用のコードを無効化
    if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then \
        sed -i 's/ -maes//g; s/ -msse4.1//g' Makefile && \
        # aesCtrCipher.h全体をx86専用にし、ARM用のダミークラスを提供
        sed -i '/#pragma once/a #if !defined(__aarch64__) && !defined(__arm__)' src/aesCtrCipher.h && \
        echo '#else' >> src/aesCtrCipher.h && \
        echo 'class AESCtrCipher { public: static bool hasAESNI() { return false; } };' >> src/aesCtrCipher.h && \
        echo '#endif' >> src/aesCtrCipher.h; \
    fi && \
    # <cstddef>ヘッダーをインクルードしsize_t未定義エラーを回避
    sed -i 's/^CXXFLAGS = \(.*\)$/CXXFLAGS = \1 -include cstddef/' Makefile && \
    PKG_CONFIG_PATH="/opt/tsduck/share/pkgconfig:${PKG_CONFIG_PATH}" \
    make CXX=clang++ && \
    make install

FROM debian:bookworm-slim AS release

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libedit2 \
    libcurl4 \
    libccid \
    pcscd \
    pcsc-tools \
    socat &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy TSDuck files
COPY --from=tsduck-build /opt/tsduck /opt/tsduck
RUN echo /opt/tsduck/lib > /etc/ld.so.conf.d/tsduck.conf && \
    ldconfig && \
    ln -sf /opt/tsduck/share/tsduck /usr/local/share/tsduck

# Copy Dantto4k binary
COPY --from=dantto4k-build /usr/local/bin/dantto4k /usr/local/bin/dantto4k

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
EXPOSE 40775
