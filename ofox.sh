#!/bin/bash

# Create Directory for OrangeFox
mkdir ofox
cd ofox

# Clone and Sync OrangeFox
git clone https://gitlab.com/OrangeFox/sync.git -b master
cd sync
./orangefox_sync.sh --branch 12.1 --path ~/ofox

# Clone OrangeFox tree
cd ~/ofox
rm -rf device/xiaomi/apollo
git clone https://github.com/murtazakolachi/device_xiaomi_ofox_apollo -b ofox device/xiaomi/apollo

# Just to be on safer side
export OUT_DIR=out && \
ulimit -n 16000 && \

# Build Environment
set +e
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
set -e
lunch twrp_apollo-eng && make clean && mka adbd recoveryimage
