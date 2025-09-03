#!/bin/bash

# =================================
#   Project Pixelage Build Script
# =================================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests

# --- Init ROM repo ---
repo init --depth=1 --no-repo-verify -u https://github.com/ProjectPixelage/android_manifest.git -b 15 --git-lfs && \

# --- Clone Manifest---
git clone https://github.com/MurtazaKolachi/build_manifest -b pixelage .repo/local_manifests && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)

# =============================
#  Build Environmnent Setup
# =============================

# --- Start Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
lunch pixelage_apollo-bp1a-user && \ && \
make installclean && \
mka bacon

echo "===== Build completed successfully! ====="
