FROM ubuntu:focal

LABEL maintainer="ariffjenong <arifbuditantodablekk@gmail.com>"


ENV DEBIAN_FRONTEND=noninteractive \
    USE_CCACHE=1 \
    CCACHE_DIR=/znxt/ccache \
    CCACHE_EXEC=/usr/bin/ccache
ENV LANG=C.UTF-8
ENV JAVA_OPTS=" -Xmx7G "
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=/bin:/usr/local/bin:/home/root/bin:$PATH

# Install all required packages
RUN apt-get update -q -y \
  && apt-get install -q -y --no-install-recommends \
    # Core Apt Packages
    apt-utils apt-transport-https python3-apt \
    # Linux Standard Base Packages
    sudo git ffmpeg maven nodejs ca-certificates-java pigz tar rsync rclone aria2 adb autoconf automake axel bc bison build-essential ccache lsb-core lsb-security ca-certificates systemd udev expect \
    # Upload/Download/Copy/FTP utils
    git curl wget wput axel rsync \
    # GNU and other core tools/utils
    binutils coreutils bsdmainutils util-linux patchutils libc6-dev sudo \
    # Security CLI tools
    ssh openssl libssl-dev sshpass gnupg2 gpg \
    # Tools for interacting with an Android platform
    android-sdk-platform-tools adb fastboot squashfs-tools \
    # OpenJDK8 as Java Runtime
    openjdk-11-jdk ca-certificates-java \
    maven nodejs \
    # Python packages
    python-all-dev python3-dev python3-requests \
    # Compression tools/utils/libraries
    zip unzip lzip lzop zlib1g-dev xzdec xz-utils pixz p7zip-full p7zip-rar zstd libzstd-dev lib32z1-dev \
    # GNU C/C++ compilers and Build Systems
    build-essential gcc gcc-multilib g++ g++-multilib \
    # make system and stuff
    clang llvm lld cmake automake autoconf \
    # XML libraries and stuff
    libxml2 libxml2-utils xsltproc expat re2c \
    # Developer's Libraries for ncurses
    ncurses-bin libncurses5-dev lib32ncurses5-dev bc libreadline-gplv2-dev libsdl1.2-dev libtinfo5 python-is-python2 ninja-build libcrypt-dev\
    # Misc utils
    file gawk xterm screen rename tree schedtool software-properties-common \
    dos2unix jq flex bison gperf exfat-utils exfat-fuse libb2-dev pngcrush imagemagick optipng advancecomp \
    # LTS specific Unique packages
    ${UNIQ_PACKAGES} \
    # Additional
    kmod \
  && unset UNIQ_PACKAGES \
  # Remove useless jre
  && apt-get -y purge default-jre-headless openjdk-11-jre-headless \
  # Show installed packages
  && apt list --installed \
  # Clean useless apt cache
  && apt-get -y clean && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
  && dpkg-divert --local --rename /usr/bin/ischroot && ln -sf /bin/true /usr/bin/ischroot \
  && chmod u+s /usr/bin/screen && chmod 755 /var/run/screen \
  && echo "Set disable_coredump false" >> /etc/sudo.conf

WORKDIR /home

RUN set -xe \
  && mkdir -p /home/root/bin \
  && curl -sL https://gerrit.googlesource.com/git-repo/+/refs/heads/stable/repo?format=TEXT | base64 --decode  > /home/root/bin/repo \
  && curl -s https://api.github.com/repos/tcnksm/ghr/releases/latest \
    | jq -r '.assets[] | select(.browser_download_url | contains("linux_amd64")) | .browser_download_url' | wget -qi - \
  && tar -xzf ghr_*_amd64.tar.gz --wildcards 'ghr*/ghr' --strip-components 1 \
  && mv ./ghr /home/root/bin/ && rm -rf ghr_*_amd64.tar.gz \
  && chmod a+rx /home/root/bin/repo \
  && chmod a+x /home/root/bin/ghr
  

WORKDIR /home/root

RUN set -xe \
  && mkdir -p extra && cd extra \
  && wget -q https://ftp.gnu.org/gnu/make/make-4.3.tar.gz \
  && tar xzf make-4.3.tar.gz \
  && cd make-*/ \
  && ./configure && bash ./build.sh 1>/dev/null && install ./make /usr/local/bin/make \
  && cd .. \
  && git clone https://github.com/ccache/ccache.git \
  && cd ccache && git checkout -q v4.2 \
  && mkdir build && cd build \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr .. \
  && make -j8 && make install \
  && cd ../../.. \
  && rm -rf extra

# Set up udev rules for adb
RUN set -xe \
  && curl --create-dirs -sL -o /etc/udev/rules.d/51-android.rules -O -L https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules \
  && chmod 644 /etc/udev/rules.d/51-android.rules \
  && chown root /etc/udev/rules.d/51-android.rules

USER root

VOLUME ["/home/root", "/znxt/ccache"]
  

WORKDIR /home/root

RUN set -xe \
  && mkdir znxt \
  && mkdir -p .config/rclone \
  && echo "secrets.RCLONE_CONFIG" > .config/rclone/rclone.conf \
  && rclone copy znxtproject:ccache/rom/ccache.tar.gz znxt -P \
  && cd znxt \
  && tar xf ccache.tar.gz \
  && rm ccache.tar.gz && cd .. \
  && mkdir rom && cd rom \
  && repo init --depth=1 --no-repo-verify -u https://github.com/ariffjenong/android.git -b lineage-19.1 -g default,-mips,-darwin,-notdefault \
  && git clone https://github.com/ariffjenong/local_manifest.git --depth=1 -b LOS19 .repo/local_manifests \
  && repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j24 || repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j24 \
  && . build/envsetup.sh \
  && lunch lineage_maple_dsds-userdebug \
  && export SELINUX_IGNORE_NEVERALLOWS=true \
  && export CCACHE_DIR=/znxt/ccache \
  && export CCACHE_EXEC=$(which ccache) \
  && export USE_CCACHE=1 \
  && export ALLOW_MISSING_DEPENDENCIES=true \
  && export WITH_GMS=false \
  && export BUILD_HOSTNAME=ArifJeNong \
  && export BUILD_USERNAME=ArifJeNong \
  && export TZ=Asia/Jakarta \
  && make bacon -j(nproc --all) \
  && cd out/target/product/maple_dsds \
  && rclone copy $(ls *maple*UNOFFICIAL*.zip) znxtproject:rom/lineage-19.1 -P && rclone copy $(ls *.md5sum) znxtproject:rom/lineage-19.1 -P
  

WORKDIR /home/root

RUN set -xe \
   && rm -rf rom && rm -rf znxt/ccache && rm -rf .config