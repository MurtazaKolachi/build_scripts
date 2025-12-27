#!/bin/bash

# Create Directory for OrangeFox
mkdir OrangeFox
cd OrangeFox

# Just to be on safer side
export OUT_DIR=out
ulimit -n 16000

# Clone and Sync OrangeFox
git clone https://gitlab.com/OrangeFox/sync.git -b master
cd sync
./orangefox_sync.sh --branch 12.1 --path ~/OrangeFox

# Clone OrangeFox tree
cd ~/OrangeFox
rm -rf device/xiaomi/apollo
git clone https://github.com/murtazakolachi/device_xiaomi_ofox_apollo -b fox-12.1 ./device/xiaomi/apollo

# Build Environment
set +e
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
set -e
lunch twrp_apollo-eng && make clean && mka adbd recoveryimage
