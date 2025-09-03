#!/bin/bash

# =================================
#   Project Pixelage Build Script
# =================================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests

# --- Init ROM repo ---
repo init --depth=1 --no-repo-verify -u https://github.com/AOSPA/manifest.git -b vauxite --git-lfs && \

# --- Clone Manifest---
git clone https://github.com/MurtazaKolachi/build_manifest -b aospa .repo/local_manifests && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)

# =============================
#  Build Environmnent Setup
# =============================

# --- Start Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
./rom-build.sh apollo

echo "===== Build completed successfully! ====="
