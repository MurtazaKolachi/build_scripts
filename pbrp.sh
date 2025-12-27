#!/bin/bash

# Create Directories
mkdir pbrp
cd pbrp

# Create Directory for OrangeFox
repo init -u https://github.com/PitchBlackRecoveryProject/manifest_pb -b android-12.1 && \
repo sync && \

# Clone TWRP tree
rm -rf device/xiaomi/apollo && \
git clone https://github.com/murtazakolachi/device_xiaomi_ofox_apollo -b pbrp device/xiaomi/apollo && \
#git clone https://github.com/murtazakolachi/device_xiaomi_ofox_apollo -b fbev2 device/xiaomi/apollo && \

# Enable ccache
# export USE_CCACHE=1
# export CCACHE_EXEC=$(which ccache)

# Just to be on safer side
export OUT_DIR=out && \
ulimit -n 16000 && \

# Build Environment
export ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh && \
lunch pb_apollo-eng && \
mka pbrp recoveryimage
