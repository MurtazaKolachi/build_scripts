#!/bin/bash

# =============================
#  CrDroid Build Script
#  For: Vanilla
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests

# --- Init ROM repo ---
repo init -u https://github.com/Mi-Apollo/cr_android.git -b 15.0 --git-lfs && \

# --- Clone Manifest---
git clone https://github.com/MurtazaKolachi/build_manifest -b 16.0 .repo/local_manifests && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync && \

# =============================
#       Build: Vanilla
# =============================

# --- Vanilla Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
breakfast apollo user && \
make installclean && \
mka bacon

echo "===== Build completed successfully! ====="