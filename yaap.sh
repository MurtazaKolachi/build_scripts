#!/bin/bash

# =============================
#  Project YAAP Build Script
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests

# --- Init ROM repo ---
repo init --depth=1 --no-repo-verify -u https://github.com/yaap/manifest.git -b sixteen --git-lfs && \

# --- Clone Manifest---
git clone https://github.com/MurtazaKolachi/build_manifest -b yaap .repo/local_manifests && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)

# =============================
#  Build Environment Setup
# =============================

# --- Start Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
lunch yaap_apollo-user && \
make installclean && \
m yaap -j$(nproc --all)

echo "===== Build completed successfully! ====="