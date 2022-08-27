FROM alpine:3.16

ENV X264_VERSION=20160826-2245-stable \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    SRC=/usr/local

COPY *.patch /root/

RUN buildDeps="autoconf \
    automake \
    bash \
    binutils \
    bzip2 \
    cmake \
    curl \
    coreutils \
    g++ \
    gcc \
    git \
    libtool \
    make \
    openssl-dev \
    tar \
    yasm \
    zlib-dev" && \
    export MAKEFLAGS="-j$(($(grep -c ^processor /proc/cpuinfo) + 1))" && \
    apk  add --update ${buildDeps} freetype-dev fontconfig-dev ttf-droid libgcc libstdc++ ca-certificates && \
    DIR=$(mktemp -d) && cd ${DIR} && \
    curl -sL https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
    tar -jx --strip-components=1 && \
    ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --enable-pic --enable-shared --disable-cli && \
    make && \
    make install && \
    rm -rf ${DIR}

## ffmpeg source from github
RUN DIR=$(mktemp -d) && cd ${DIR} && \
    git clone https://github.com/FFmpeg/FFmpeg.git . && \
    git checkout --detach ca21cb1e36ccae2ee71d4299d477fa9284c1f551 && \
    cp /root/*.patch . && \
    git apply -v *.patch && \
    ./configure --prefix="${SRC}" \
    --extra-cflags="-I${SRC}/include" \
    --extra-ldflags="-L${SRC}/lib" \
    --bindir="${SRC}/bin" \
    --disable-doc \
    --disable-static \
    --enable-shared \
    --disable-ffplay \
    --extra-libs=-ldl \
    --enable-version3 \
    --enable-libx264 \
    --enable-libfontconfig \
    --enable-libfreetype \
    --enable-gpl \
    --enable-avresample \
    --enable-postproc \
    --enable-nonfree \
    --disable-debug \
    --enable-openssl && \
    make && \
    make install && \
    make distclean && \
    hash -r && \
    rm -rf ${DIR} && \
    cd && \
    apk del ${buildDeps} && \
    rm -rf /var/cache/apk/* /usr/local/include && \
    ffmpeg -buildconf
