#!/bin/bash

# =============================
#    Derpfest Build Script
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests

# --- Init ROM repo ---
repo init --depth=1 --no-repo-verify -u https://github.com/DerpFest-LOS/android_manifest.git -b 15.2 --git-lfs && \

# --- Clone Manifest---
git clone https://github.com/MurtazaKolachi/build_manifest -b derp .repo/local_manifests && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)

# =============================
#  Build Environment Setup
# =============================

# --- Start Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
lunch lineage_apollo-bp1a-user && \
make installclean && \
mka derp -j$(nproc --all)

echo "===== All builds completed successfully! ====="