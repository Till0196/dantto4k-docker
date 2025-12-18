FROM debian:trixie AS base

WORKDIR /app
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    curl \
    gpg \
    lsb-release && \
    curl -fsSL https://apt.llvm.org/llvm.sh | bash && \
    # Set up alternatives for clang/clang++ without version suffix
    CLANG_VERSION=$(ls /usr/bin/clang-* | grep -o '[0-9]\+' | head -1) && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION} 100 && \
    update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-${CLANG_VERSION} 100 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM base AS casproxyserver-build
# renovate: datasource=github-releases depName=nekohkr/casproxyserver
ARG CASPROXYSERVER_VERSION=1.0.0

WORKDIR /app

# Install casproxyserver dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    libpcsclite-dev \
    make \
    cmake \
    pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v${CASPROXYSERVER_VERSION} --recurse-submodules https://github.com/nekohkr/casproxyserver.git /tmp/casproxyserver && \
    cd /tmp/casproxyserver && \
    cd thirdparty/yaml-cpp && \
    cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded && \
    cmake --build build --config Release && \
    cd ../.. && \
    # <cstddef>ヘッダーをインクルードしsize_t未定義エラーを回避
    sed -i 's/^CXXFLAGS = \(.*\)$/CXXFLAGS = \1 -include cstddef/' Makefile && \
    make CXX=clang++ && \
    make install && \
    mkdir -p /opt/usr/local/bin && \
    mkdir -p /opt/usr/local/etc && \
    cp /usr/local/bin/casproxyserver /opt/usr/local/bin/casproxyserver && \
    cp /tmp/casproxyserver/scripts/config.yml /opt/usr/local/etc/casproxyserver.yml

FROM debian:trixie-slim AS release

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    pcscd \
    pcsc-tools &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy casproxyserver files
COPY --from=casproxyserver-build /opt/usr/local /usr/local

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
EXPOSE 24000
