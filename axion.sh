#!/bin/bash

# =============================
#  Axion AOSP Build Script
#  For: Vanilla → Gapps
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# Better to use these to avoid any problems on crave
rm -rf device/xiaomi &&
rm -rf vendor/xiaomi &&
rm -rf kernel/xiaomi &&
rm -rf hardware/xiaomi &&
rm -rf hardware/dolby &&
rm -rf packages/apps/ViPER4AndroidFX &&
rm -rf packages/resources/devicesettings &&
rm -rf vendor/lineage-priv/keys &&
rm -rf out/target/product/vanilla &&
rm -rf out/target/product/gapps &&

# --- Init ROM repo ---
repo init -u https://github.com/Mi-Apollo/axion_android -b lineage-23.0 --git-lfs && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/device_xiaomi_apollo -b axion device/xiaomi/apollo && \

# --- Clone Vendor Tree ---
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/vendor_xiaomi_apollo -b 16 vendor/xiaomi/apollo && \

# --- Clone Kernel Tree ---
rm -rf kernel/xiaomi
git clone https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b 16 kernel/xiaomi/apollo && \

# --- Clone Hardware Tree ---
rm -rf hardware/xiaomi
# git clone https://github.com/LineageOS/android_hardware_xiaomi -b lineage-23.0 hardware/xiaomi && \
git clone https://github.com/Evolution-X-Devices/hardware_xiaomi -b bka hardware/xiaomi && \

# --- Dolby ---
# rm -rf hardware/dolby
# git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \

# --- Device Settings ---
rm -rf packages/resources/devicesettings
git clone https://github.com/PocoF3Releases/packages_resources_devicesettings -b aosp-16 packages/resources/devicesettings && \

# Private Keys
rm -rf vendor/lineage-priv/keys
git clone https://github.com/MurtazaKolachi/keys -b axion vendor/lineage-priv/keys && \

# WFD Repos
#git clone https://github.com/PocoF3Releases/device_qcom_wfd device/qcom/wfd && \
#git clone https://github.com/PocoF3Releases/vendor_qcom_wfd vendor/qcom/wfd && \

# =============================
#   Build: Vanilla → Gapps
# =============================

# --- Vanilla Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
axion apollo user va && \
make installclean && \
ax -br && \
mv device/xiaomi/apollo/lineage_apollo.mk device/xiaomi/apollo/vanilla.txt && \

echo "===== Handling Vanilla Output ====="
mv out/target/product/apollo out/target/product/vanilla && \

# --- Gapps Build ---
echo "===== Setting up for Gapps Build ====="
mv device/xiaomi/apollo/gapps.txt device/xiaomi/apollo/lineage_apollo.mk && \
axion apollo user gms pico && \
make installclean && \
ax -br && \
mv device/xiaomi/apollo/lineage_apollo.mk device/xiaomi/apollo/gapps.txt && \

echo "===== Handling Gapps Output ====="
mv out/target/product/apollo out/target/product/gapps && \

# --- Restore Vanilla ---
mv device/xiaomi/apollo/vanilla.txt device/xiaomi/apollo/lineage_apollo.mk && \

echo "===== All builds completed successfully! ====="
