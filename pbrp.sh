#!/bin/bash

# Create Directories
mkdir pbrp
cd pbrp

# Create Directory for OrangeFox
repo init -u https://github.com/PitchBlackRecoveryProject/manifest_pb -b android-12.1 && \
repo sync && \

# Just to be on safer side
export OUT_DIR=out && \
ulimit -n 16000 && \

# Clone TWRP tree
rm -rf device/xiaomi/apollo && \
rm -rf device/xiaomi/umi && \
git clone https://github.com/murtazakolachi/device_xiaomi_ofox_apollo -b test device/xiaomi/umi && \
#git clone https://github.com/murtazakolachi/device_xiaomi_ofox_apollo -b fbev2 device/xiaomi/apollo && \

# Enable ccache
# export USE_CCACHE=1
# export CCACHE_EXEC=$(which ccache)

# Build Environment
export ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh && \
lunch pb_apollo-eng && \
mka recoveryimage
