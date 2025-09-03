#!/bin/bash

# =============================
#  RisingOS Revived Build Script
#  For: Vanilla → Gapps → MicroG
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests

# --- Init ROM repo ---
repo init --depth=1 --no-repo-verify -u https://github.com/RisingOS-Revived/android.git -b sixteen && \

# --- Clone Manifest---
git clone https://github.com/MurtazaKolachi/build_manifest -b rising .repo/local_manifests && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)

# =============================
#  Build: Vanilla → Gapps → MicroG
# =============================

# --- Vanilla Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
riseup apollo user && \
make installclean && \
rise b && \
mv device/xiaomi/apollo/lineage_apollo.mk device/xiaomi/apollo/vanilla.txt && \

echo "===== Handling Vanilla Output ====="
mv out/target/product/apollo out/target/product/vanilla && \

# --- Gapps Build ---
echo "===== Setting up for Gapps Build ====="
mv device/xiaomi/apollo/gapps.txt device/xiaomi/apollo/lineage_apollo.mk && \
make installclean && \
rise b -j$(nproc --all) && \
mv device/xiaomi/apollo/lineage_apollo.mk device/xiaomi/apollo/gapps.txt && \

echo "===== Handling Gapps Output ====="
mv out/target/product/apollo out/target/product/gapps && \

# --- MicroG Build ---
echo "===== Setting up for MicroG Build ====="
mv device/xiaomi/apollo/microg.txt device/xiaomi/apollo/lineage_apollo.mk && \
make installclean && \
rise b -j$(nproc --all) && \
mv device/xiaomi/apollo/lineage_apollo.mk device/xiaomi/apollo/microg.txt && \

echo "===== Handling MicroG Output ====="
mv out/target/product/apollo out/target/product/microg && \

# --- Restore Vanilla ---
mv device/xiaomi/apollo/vanilla.txt device/xiaomi/apollo/lineage_apollo.mk && \

echo "===== All builds completed successfully! ====="
