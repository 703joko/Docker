FROM ubuntu:22.04
LABEL maintainer="ariffjenong <arifbuditantodablekk@gmail.com>"
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /cirrus

RUN apt-get -yqq update \
    && mkdir -p rom \
    && mkdir -p /usr/local/bin \
    && apt-get install --no-install-recommends -yqq adb cloud-guest-utils iproute2 libxml2-dev libxslt1-dev libmemcached-dev awscli libgd-dev libzip-dev asciidoctor docbook-xml docbook-xsl elfutils bash libhiredis-dev redis-server redis-tools sudo tzdata locales python-is-python3 python3-pip pigz tar rsync rclone aria2 ccache curl wget zip unzip lzip lzop zlib1g-dev xzdec xz-utils pixz p7zip-full p7zip-rar zstd libzstd-dev lib32z1-dev ffmpeg maven nodejs ca-certificates-java pigz tar rsync rclone aria2 libncurses5 adb autoconf automake axel bc bison build-essential ccache clang* cmake brotli curl expat fastboot flex g++ g++-multilib gawk gcc gcc-multilib git gnupg gperf htop imagemagick locales libncurses5 lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev libsdl1.2-dev libssl-dev libtool libxml-simple-perl libxml2 libxml2-utils lsb-core lzip '^lzma.*' lzop maven nano ncftp ncurses-dev openssh-server openssh-client sshpass patch patchelf pkg-config pngcrush pngquant python2.7 python-all-dev re2c rclone rsync schedtool squashfs-tools subversion sudo tar texinfo tmate tzdata unzip w3m xsltproc zip zlib1g-dev zram-config zstd axel flex bison ncurses-dev texinfo gperf patch libtool automake libncurses5-dev gawk subversion expat libexpat1-dev python-all-dev binutils-dev bc libcap-dev autoconf libgmp-dev build-essential pkg-config libmpc-dev libmpfr-dev autopoint gettext txt2man liblzma-dev libssl-dev libz-dev mercurial tar cmake ninja-build zstd lz4 liblz4-tool liblz4-dev lzma openjdk-17* golang-go lsb-release software-properties-common docker.io help2man jq rsync --fix-broken --fix-missing \
    && apt-get install --no-install-recommends -yqq adb pigz autoconf automake axel bc bison build-essential ccache clang cmake curl expat expect fastboot flex g++ g++-multilib gawk gcc gcc-multilib git gnupg gperf htop imagemagick locales libncurses5 lib32ncurses5-dev lib32z1-dev brotli libtinfo5 libc6-dev libcap-dev libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev libnl-route-3-dev libprotobuf-dev libsdl1.2-dev libssl-dev libtool libxml-simple-perl libxml2 libxml2-utils lld lsb-core lzip '^lzma.*' lzop maven nano ncftp ncurses-dev openssh-server patch patchelf pkg-config pngcrush pngquant protobuf-compiler python-is-python3 python3-pip python2.7 python3-apt python-all-dev re2c rclone rsync schedtool screen squashfs-tools subversion sudo tar texinfo tmate tzdata unzip w3m wget xsltproc zip zlib1g-dev zram-config zstd \
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

RUN git clone https://github.com/ninja-build/ninja.git \
    && cd ninja && ./configure.py --bootstrap \
    && sudo install ./ninja /usr/bin/ninja

RUN git clone https://github.com/google/kati.git \
    && cd kati && make ckati \
    && sudo install ./ckati /usr/bin/ckati

RUN git clone https://github.com/google/nsjail.git \
    && cd nsjail && make nsjail \
    && sudo install ./nsjail /usr/bin/nsjail

RUN axel -a -n 10 https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz \
    && tar xvzf zstd-1.5.2.tar.gz && cd zstd-1.5.2 \
    && sudo make install

RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && unzip rclone-current-linux-amd64.zip && cd rclone-*-linux-amd64 \
    && sudo cp rclone /usr/bin/ && sudo chown root:root /usr/bin/rclone \
    && sudo chmod 755 /usr/bin/rclone

WORKDIR /cirrus/script

RUN bash setup/android_build_env.sh

WORKDIR /cirrus

RUN rm zstd-1.5.2.tar.gz rclone-current-linux-amd64.zip \
    && rm -rf rclone-v1.61.1-linux-amd64 \
    && rm -rf kati make ninja nsjail rclone-v1.58.0-linux-amd64 script zstd-1.5.2 \
    && ls

VOLUME ["/cirrus/ccache", "/cirrus/rom"]
ENTRYPOINT ["/bin/bash"]
