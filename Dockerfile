FROM ubuntu:focal
LABEL maintainer="ariffjenong <arifbuditantodablekk@gmail.com>"
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /cirrus

RUN apt-get -yqq update \
    && mkdir -p rom \
    && mkdir -p script \
    && apt-get install --no-install-recommends -yqq adb pigz autoconf automake axel bc bison build-essential ccache clang cmake curl expat expect fastboot flex g++ g++-multilib gawk gcc gcc-multilib git gnupg gperf htop imagemagick locales libncurses5 lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev libnl-route-3-dev libprotobuf-dev libsdl1.2-dev libssl-dev libtool libxml-simple-perl libxml2 libxml2-utils lld lsb-core lzip '^lzma.*' lzop maven nano ncftp ncurses-dev openssh-server patch patchelf pkg-config pngcrush pngquant protobuf-compiler python2.7 python3-apt python-all-dev python re2c rclone rsync schedtool screen squashfs-tools subversion sudo tar texinfo tmate tzdata unzip w3m wget xsltproc zip zlib1g-dev zram-config zstd \
    && curl --create-dirs -L -o /usr/local/bin/repo -O -L https://raw.githubusercontent.com/geopd/git-repo/main/repo \
    && chmod a+rx /usr/local/bin/repo \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen \
    && git clone https://github.com/akhilnarang/scripts script \
    && TZ=Asia/Jakarta \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN git clone https://github.com/mirror/make \
    && cd make && ./bootstrap && ./configure && make CFLAGS="-O3 -Wno-error" \
    && sudo install ./make /usr/bin/make

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

WORKDIR /cirrus/rom

RUN repo init --depth=1 --no-repo-verify -u https://github.com/CherishOS/android_manifest.git -b twelve-one -g default,-mips,-darwin,-notdefault \
    && git clone https://github.com/ariffjenong/local_manifest.git --depth=1 -b cherish-12.1 .repo/local_manifests \
    && repo sync external/tinyxml2 external/toybox external/wayland frameworks/compile/slang frameworks/compile/mclinker frameworks/compile/libbcc frameworks/ex frameworks/layoutlib frameworks/libs/modules-utils frameworks/libs/net frameworks/libs/native_bridge_support frameworks/libs/service_entitlement frameworks/minikin frameworks/opt/bitmap frameworks/opt/calendar frameworks/opt/car/services frameworks/opt/car/setupwizard frameworks/opt/chips frameworks/opt/colorpicker frameworks/opt/localepicker frameworks/opt/net/ethernet frameworks/opt/net/voip frameworks/opt/net/wifi system/libbase system/libprocinfo system/libsysprop system/libufdt system/libvintf system/nfc system/linkerconfig prebuilts/vndk/v30 prebuilts/vndk/v31 prebuilts/build-tools pdk libnativehelper libcore external/ims external/icing external/icu system/apex vendor/nxp/opensource/sn100x/hidlimpl vendor/nxp/opensource/sn100x/halimpl vendor/nxp/opensource/pn5xx/halimpl vendor/nxp/opensource/pn5xx/hidlimpl packages/resources/devicesettings external/wpa_supplicant_8 external/libnfc-nxp external/json-c external/exfatprogs external/ant-wireless/antradio-library external/ant-wireless/hidl external/ant-wireless/ant_service external/ant-wireless/ant_native external/ant-wireless/ant_client packages/services/Telephony packages/services/Telecomm packages/modules/Connectivity packages/modules/adb packages/providers/TelephonyProvider packages/providers/MediaProvider packages/providers/ContactsProvider packages/providers/DownloadProvider packages/apps/WallpaperPicker2 packages/apps/RepainterServicePriv packages/apps/Updates packages/apps/SimpleDeviceConfig packages/apps/SettingsIntelligence packages/apps/FaceUnlockService packages/apps/GamingMode packages/apps/Bluetooth vendor/qcom/opensource/commonsys-intf/display vendor/qcom/opensource/cryptfs_hw vendor/qcom/opensource/data-ipa-cfg-mgr vendor/qcom/opensource/dataservices vendor/qcom/opensource/healthd-ext vendor/qcom/opensource/libfmjni vendor/qcom/opensource/thermal-engine vendor/qcom/opensource/wfd-commonsys vendor/qcom/opensource/usb hardware/qcom-caf/msm8998/media hardware/qcom-caf/msm8998/display hardware/qcom-caf/msm8998/audio tools/extract-utils prebuilts/tools-cherish prebuilts/extract-tools system/tools/dtbtool system/qcom hardware/qcom-caf/common hardware/qcom-caf/bootctrl hardware/lineage/livedisplay vendor/nxp/opensource/commonsys/packages/apps/Nfc vendor/nxp/opensource/commonsys/frameworks vendor/nxp/opensource/commonsys/external/libnfc-nci vendor/nxp/opensource/interfaces/nfc vendor/qcom/opensource/interfaces vendor/qcom/opensource/fm-commonsys vendor/qcom/opensource/commonsys/system/bt vendor/qcom/opensource/commonsys/packages/apps/Bluetooth vendor/qcom/opensource/commonsys/bluetooth_ext vendor/qcom/opensource/commonsys-intf/bluetooth vendor/qcom/opensource/audio-hal/st-hal vendor/qcom/opensource/audio vendor/qcom/opensource/commonsys/display vendor/qcom/opensource/display vendor/lawnchair vendor/lawnicons vendor/qcom/opensource/power system/bt system/core system/logging system/libhwbinder system/memory/lmkd system/netd system/security system/vold system/update_engine system/sepolicy packages/apps/Settings packages/apps/CherishSettings hardware/qcom-caf/wlan hardware/libhardware hardware/cherish/interfaces frameworks/opt/telephony hardware/interfaces frameworks/libs/systemui frameworks/libs/net external/themelib external/tinycompress external/selinux external/mksh external/libcxx external/gptfdisk external/fastrpc external/faceunlock external/e2fsprogs external/colorkt device/qcom/sepolicy-legacy-um device/qcom/sepolicy-legacy device/qcom/sepolicy device/cherish/sepolicy frameworks/opt/net/ims vendor/codeaurora/telephony vendor/gapps build/make bionic art sdk build/soong vendor/cherish frameworks/native frameworks/av frameworks/base kernel/sony/msm8998 device/sony/maple_dsds device/sony/yoshino-common vendor/sony/maple_dsds -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j8

WORKDIR /cirrus/script

RUN bash setup/android_build_env.sh

WORKDIR /cirrus

RUN rm zstd-1.5.2.tar.gz rclone-current-linux-amd64.zip \
    && rm -rf brotli kati make ninja nsjail rclone-v1.58.0-linux-amd64 script zstd-1.5.2

VOLUME ["/cirrus/ccache", "/cirrus/rom"]
ENTRYPOINT ["/bin/bash"]
