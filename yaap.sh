#!/bin/bash

# =============================
#  Project YAAP Build Script
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Remove Device Settings --- (Reason: It Will fail sync when we re run this script)
rm -rf packages/resources/devicesettings

# --- Init ROM repo ---
repo init -u https://github.com/yaap/manifest.git -b sixteen --git-lfs && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/device_xiaomi_apollo -b yaap device/xiaomi/apollo && \

# --- Clone Vendor Tree ---
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/vendor_xiaomi_apollo -b 16 vendor/xiaomi/apollo && \

# --- Clone Kernel Tree ---
rm -rf kernel/xiaomi
git clone https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b 16 kernel/xiaomi/apollo && \

# --- Clone Hardware Tree ---
rm -rf hardware/xiaomi
# git clone https://github.com/LineageOS/android_hardware_xiaomi -b lineage-23.0 hardware/xiaomi && \
git clone https://github.com/Evolution-X-Devices/hardware_xiaomi -b bka hardware/xiaomi && \ && \

# --- Dolby ---
# rm -rf hardware/dolby
# git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \

# --- ViPER ---
rm -rf packages/apps/ViPER4AndroidFX
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \

# --- Device Settings ---
rm -rf packages/resources/devicesettings
git clone https://github.com/MurtazaKolachi/android_packages_resources_devicesettings -b lineage-23.0 packages/resources/devicesettings && \

# WFD repos
# git clone https://github.com/PocoF3Releases/device_qcom_wfd device/qcom/wfd && \
# git clone https://github.com/PocoF3Releases/vendor_qcom_wfd vendor/qcom/wfd && \

# =============================
#  Build Environment Setup
# =============================

# --- Start Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
lunch yaap_apollo-user && \
make installclean && \
m yaap

echo "===== Build completed successfully! ====="