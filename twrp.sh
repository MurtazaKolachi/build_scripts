#!/bin/bash

# Create Directories
mkdir twrp
cd twrp

# Create Directory for OrangeFox
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1 && \
repo sync && \

# Just to be on safer side
export OUT_DIR=out && \
ulimit -n 16000 && \

# Clone TWRP tree
rm -rf device/xiaomi/apollo && \
git clone https://github.com/murtazakolachi/device_xiaomi_ofox_apollo -b twrp device/xiaomi/apollo && \
#git clone https://github.com/murtazakolachi/device_xiaomi_ofox_apollo -b fbev2 device/xiaomi/apollo && \

# Enable ccache
# export USE_CCACHE=1
# export CCACHE_EXEC=$(which ccache)

# Build Environment
export ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh && \
lunch twrp_apollo-eng && \
mka recoveryimage
