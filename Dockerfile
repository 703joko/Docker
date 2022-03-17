FROM ubuntu:20.04 as base-image

LABEL maintainer="ariffjenong <arifbuditantodablekk@gmail.com>"

RUN uname -a && uname -m

ENV ANDROID_HOME="/opt/android-sdk"

# support amd64 and arm64
RUN JDK_PLATFORM=$(if [ "$(uname -m)" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    echo export JDK_PLATFORM=$JDK_PLATFORM >> /etc/jdk.env && \
    echo export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-$JDK_PLATFORM/" >> /etc/jdk.env && \
    echo . /etc/jdk.env >> /etc/bash.bashrc && \
    echo . /etc/jdk.env >> /etc/profile

ENV TZ=Asia/Jakarta

# Get the latest version from https://developer.android.com/studio/index.html
ENV ANDROID_SDK_TOOLS_VERSION="6200805_latest"


# Set locale
ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

RUN apt-get clean && \
    apt-get update && \
    apt-get install -y apt-utils locales && \
    locale-gen $LANG

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM=dumb \
    DEBIAN_FRONTEND=noninteractive \
    USE_CCACHE=1 \
    CCACHE_DIR=/znxt/ccache \
    CCACHE_EXEC=/usr/bin/ccache

# Variables must be references after they are created
ENV ANDROID_SDK_HOME="$ANDROID_HOME"

ENV PATH="$JAVA_HOME/bin:$PATH:$ANDROID_SDK_HOME/emulator:$ANDROID_SDK_HOME/tools/bin:$ANDROID_SDK_HOME/tools:$ANDROID_SDK_HOME/platform-tools"

WORKDIR /tmp


# Installing packages
RUN apt-get update > /dev/null && \
    apt-get install locales > /dev/null && \
    locale-gen "$LANG" > /dev/null && \
    apt-get install -y --no-install-recommends \
        autoconf \
        build-essential \
        curl \
        file \
        git \
        gpg-agent \
        less \
        libc6-dev \
        libgmp-dev \
        libmpc-dev \
        libmpfr-dev \
        libxslt-dev \
        libxml2-dev \
        m4 \
        ncurses-dev \
        openjdk-11-jdk \
        openssh-client \
        pkg-config \
        software-properties-common \
        tzdata \
        unzip \
        vim-tiny \
        wget \
        zip \
        ssh openssl libssl-dev sshpass gnupg2 gpg \
        ca-certificates-java \
        python-all-dev python3-dev python3-requests \
        binutils coreutils bsdmainutils util-linux patchutils libc6-dev \
        apt-utils apt-transport-https python3-apt \
        wput axel rsync \
    dos2unix jq flex bison gperf exfat-utils exfat-fuse libb2-dev pngcrush imagemagick optipng advancecomp \
    build-essential gcc gcc-multilib g++ g++-multilib \
    clang llvm lld cmake automake autoconf \
    file gawk xterm screen rename tree schedtool software-properties-common \
    ncurses-bin libncurses5-dev lib32ncurses5-dev bc libreadline-gplv2-dev libsdl1.2-dev libtinfo5 python-is-python2 ninja-build libcrypt-dev\
    libxml2 libxml2-utils xsltproc expat re2c \
    zip unzip lzip lzop zlib1g-dev xzdec xz-utils pixz p7zip-full p7zip-rar zstd libzstd-dev lib32z1-dev \
        sudo git ffmpeg maven nodejs ca-certificates-java pigz tar rsync rclone aria2 adb autoconf automake axel bc bison build-essential ccache lsb-core lsb-security ca-certificates systemd udev expect \
        zlib1g-dev > /dev/null && \
    echo "JVM directories: `ls -l /usr/lib/jvm/`" && \
    . /etc/jdk.env && \
    echo "Java version (default):" && \
    java -version && \
    echo "set timezone" && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    rm -rf /tmp/* /var/tmp/* \
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

# Install Android SDK
RUN echo "sdk tools ${ANDROID_SDK_TOOLS_VERSION}" && \
    wget --quiet --output-document=sdk-tools.zip \
        "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip" && \
    mkdir --parents "$ANDROID_HOME"/cmdline-tools && \
    unzip -q sdk-tools.zip -d "$ANDROID_HOME"/cmdline-tools  && \
    rm --force sdk-tools.zip

# Install SDKs
# Please keep these in descending order!
# The `yes` is for accepting all non-standard tool licenses.
RUN mkdir --parents "$ANDROID_HOME/.android/" && \
    echo '### User Sources for Android SDK Manager' > \
        "$ANDROID_HOME/.android/repositories.cfg" && \
    . /etc/jdk.env && \
    yes | "$ANDROID_HOME"/cmdline-tools/tools/bin/sdkmanager --licenses > /dev/null

# List all available packages.
# redirect to a temp file `packages.txt` for later use and avoid show progress
RUN . /etc/jdk.env && \
    "$ANDROID_HOME"/cmdline-tools/tools/bin/sdkmanager --list > packages.txt && \
    cat packages.txt | grep -v '='

#
# https://developer.android.com/studio/command-line/sdkmanager.html
#
RUN echo "platforms" && \
    . /etc/jdk.env && \
    yes | "$ANDROID_HOME"/cmdline-tools/tools/bin/sdkmanager \
        "platforms;android-31" > /dev/null

RUN echo "platform tools" && \
    . /etc/jdk.env && \
    yes | "$ANDROID_HOME"/cmdline-tools/tools/bin/sdkmanager \
        "platform-tools" > /dev/null

RUN echo "build tools 31" && \
    . /etc/jdk.env && \
    yes | "$ANDROID_HOME"/cmdline-tools/tools/bin/sdkmanager \
        "build-tools;31.0.0" > /dev/null

# seems there is no emulator on arm64
# Warning: Failed to find package emulator
#RUN echo "emulator" && \
    #if [ "$(uname -m)" != "x86_64" ]; then echo "emulator only support Linux x86 64bit. skip for $(uname -m)"; exit 0; fi && \
    #. /etc/jdk.env && \
    #yes | "$ANDROID_HOME"/cmdline-tools/tools/bin/sdkmanager "emulator" > /dev/null

# List sdk directory content
RUN ls -l $ANDROID_HOME

RUN du -sh $ANDROID_HOME

# Copy sdk license agreement files.
RUN mkdir -p $ANDROID_HOME/licenses
COPY sdk/licenses/* $ANDROID_HOME/licenses/

# Add jenv to control which version of java to use, default to 11.
RUN git clone https://github.com/jenv/jenv.git ~/.jenv && \
    echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.bash_profile && \
    echo 'eval "$(jenv init -)"' >> ~/.bash_profile && \
    . ~/.bash_profile && \
    . /etc/jdk.env && \
    java -version && \
    jenv add /usr/lib/jvm/java-11-openjdk-$JDK_PLATFORM && \
    jenv versions && \
    jenv global 11 && \
    java -version

ARG BUILD_DATE=""
ARG SOURCE_BRANCH=""
ARG SOURCE_COMMIT=""
ARG DOCKER_TAG=""

ENV BUILD_DATE=${BUILD_DATE} \
    SOURCE_BRANCH=${SOURCE_BRANCH} \
    SOURCE_COMMIT=${SOURCE_COMMIT} \
    DOCKER_TAG=${DOCKER_TAG}

WORKDIR /project

USER root

COPY root/ /

RUN addgroup --quiet --gid 3142 builder
RUN adduser --disabled-password --quiet --uid 3142 --gid 3142 --gecos "CI Builder,3142,," builder

#USER builder