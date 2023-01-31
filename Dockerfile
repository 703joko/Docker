FROM ubuntu:22.04
LABEL maintainer="ariffjenong <arifbuditantodablekk@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C
ENV USE_CCACHE=1
ENV ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx120G"
ENV JAVA_OPTS=" -Xmx120G "
ENV BUILD_USERNAME=znxt
ENV CCACHE_EXEC=/usr/bin/ccache
ENV BUILD_HOSTNAME=NAD
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV USER=znxt

WORKDIR /cirrus

RUN apt-get -yqq update \
    && mkdir -p rom \
    && mkdir -p /usr/local/bin \
    && apt-get install --no-install-recommends -yqq adb pigz autoconf automake axel bc bison build-essential ccache clang cmake curl expat expect fastboot flex g++ g++-multilib gawk gcc gcc-multilib git gnupg gperf htop imagemagick locales libncurses5 lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev libnl-route-3-dev libprotobuf-dev libsdl1.2-dev libssl-dev libtool libxml-simple-perl libxml2 libxml2-utils lld lsb-core lzip '^lzma.*' lzop maven nano ncftp ncurses-dev openssh-server patch patchelf pkg-config pngcrush pngquant protobuf-compiler python-is-python3 python3-pip python2.7 python3-apt python-all-dev re2c rclone rsync schedtool screen squashfs-tools subversion sudo tar texinfo tmate tzdata unzip w3m wget xsltproc zip zlib1g-dev zram-config zstd \
    && curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo \
    && chmod a+rx /usr/local/bin/repo \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen \
    && git clone https://github.com/akhilnarang/scripts script \
    && TZ=Asia/Jakarta \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN python3 -m pip  install networkx \
    && ln -sf /usr/bin/python3 /usr/bin/python

RUN git clone https://github.com/mirror/make \
    && cd make && ./bootstrap && ./configure && make CFLAGS="-O3 -Wno-error" \
    && sudo install ./make /usr/bin/make

RUN wget https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.2.2.tar.gz \
    && tar xzf libwebp-1.2.2.tar.gz \
    && cd libwebp-1.2.2 \
    && export PATH="/usr/lib/ccache:$PATH" \
    && which clang \
    && ./configure \
    && make -j$(nproc --all)

RUN git clone https://github.com/ninja-build/ninja.git \
    && cd ninja && git reset --hard f404f00 && ./configure.py --bootstrap \
    && sudo install ./ninja /usr/bin/ninja

RUN git clone https://github.com/google/kati.git \
    && cd kati && git reset --hard ac01665 && make ckati \
    && sudo install ./ckati /usr/bin/ckati

RUN git clone https://github.com/google/nsjail.git \
    && cd nsjail && git reset --hard e678c25 && make nsjail \
    && sudo install ./nsjail /usr/bin/nsjail

RUN axel -a -n 10 https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz \
    && tar xvzf zstd-1.5.2.tar.gz && cd zstd-1.5.2 \
    && sudo make install

RUN git clone https://github.com/google/brotli.git \
    && cd brotli && mkdir out && cd out && ../configure-cmake --disable-debug \
    && make CFLAGS="-O3" && sudo make install

RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && unzip rclone-current-linux-amd64.zip && cd rclone-*-linux-amd64 \
    && sudo cp rclone /usr/bin/ && sudo chown root:root /usr/bin/rclone \
    && sudo chmod 755 /usr/bin/rclone

RUN git clone --depth 1 https://github.com/TheLartians/Ccache.cmake .Ccache.cmake \
    && cd .Ccache.cmake \
    && cmake -Htest -Bbuild -DUSE_CCACHE=YES -DCCACHE_OPTIONS="CCACHE_CPP2=true;CCACHE_SLOPPINESS=clang_index_store" \
    && cmake --build build \
    && cmake -Htest -Bbuildx -GNinja -DUSE_CCACHE=YES -DCCACHE_OPTIONS="CCACHE_CPP2=true;CCACHE_SLOPPINESS=clang_index_store" \
    && cmake --build buildx

RUN set -x \
    && curl -LO https://github.com/cli/cli/releases/download/v2.20.2/gh_2.20.2_linux_amd64.deb \
    && dpkg -i gh* \
    && rm gh*

WORKDIR /cirrus/script

RUN bash setup/android_build_env.sh

WORKDIR /cirrus

RUN rm zstd-1.5.2.tar.gz rclone-current-linux-amd64.zip \
    && rm -rf /var/lib/dpkg/info/*.postinst \
    && dpkg --configure -a \
    && rm -rf libwebp-1.2.2.tar.gz \
    && rm -rf brotli kati make ninja nsjail rclone-v1.58.0-linux-amd64 script zstd-1.5.2 \
    && ls

VOLUME ["/cirrus/ccache", "/cirrus/rom"]
ENTRYPOINT ["/bin/bash"]
