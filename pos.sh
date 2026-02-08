#!/bin/bash

# =============================
#  PixelOS Build Script
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Remove Device Settings --- (Reason: It Will fail sync when we re run this script)
rm -rf packages/resources/devicesettings

# --- Init ROM repo ---
repo init -u https://github.com/PixelOS-AOSP/manifest.git -b fifteen --git-lfs && \
repo init -u https://github.com/PixelOS-AOSP/android_manifest -b sixteen-qpr1 --git-lfs

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/device_xiaomi_apollo -b pos device/xiaomi/apollo && \

# --- Clone Vendor Tree ---
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/vendor_xiaomi_apollo -b pos vendor/xiaomi/apollo && \

# --- Clone Kernel Tree ---
rm -rf kernel/xiaomi
git clone https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b 16 kernel/xiaomi/apollo && \
#git clone https://github.com/MurtazaKolachi/android_kernel_xiaomi_apollo -b staging kernel/xiaomi/apollo && \

# --- Clone Hardware Tree ---
rm -rf hardware/xiaomi
#git clone https://github.com/MurtazaKolachi/android_hardware_xiaomi -b lineage-23.0 hardware/xiaomi && \
git clone https://github.com/Evolution-X-Devices/hardware_xiaomi -b bka hardware/xiaomi && \ && \

# --- Dolby ---
#rm -rf hardware/dolby
#git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \
#git clone https://github.com/Mi-Apollo/lunaris2_hardware_dolby -b 16.0 hardware/dolby && \

# --- ViPER ---
rm -rf packages/apps/ViPER4AndroidFX
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \

# --- Device Settings ---
rm -rf packages/resources/devicesettings
git clone https://github.com/Mi-Apollo/android_packages_resources_devicesettings -b lineage-23.2 packages/resources/devicesettings

# =============================
#  Build Environment Setup
# =============================

# --- Start Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
breakfast apollo user && \
make installclean && \
m pixelos

echo "===== Build completed successfully! ====="
