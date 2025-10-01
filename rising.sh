#!/bin/bash

# =============================
#  RisingOS Revived Build Script
#  For: Vanilla → Gapps → MicroG
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests

# --- Init ROM repo ---
repo init -u https://github.com/RisingOS-Revived/android.git -b sixteen --git-lfs && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/android_device_xiaomi_apollo -b rising device/xiaomi/apollo && \

# --- Clone Vendor Tree ---
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/android_vendor_xiaomi_apollo -b 16 vendor/xiaomi/apollo && \

# --- Clone Kernel Tree ---
rm -rf kernel/xiaomi
git clone https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b 16 kernel/xiaomi/apollo && \

# --- Clone Hardware Tree ---
rm -rf hardware/xiaomi
git clone https://github.com/LineageOS/android_hardware_xiaomi -b lineage-23.0 hardware/xiaomi && \

# --- Dolby ---
rm -rf hardware/dolby
git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \

# --- ViPER ---
rm -rf packages/apps/ViPER4AndroidFX
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \

# --- Device Settings ---
rm -rf packages/resources/devicesettings
git clone https://github.com/PocoF3Releases/packages_resources_devicesettings -b aosp-16 packages/resources/devicesettings

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
rise b && \
mv device/xiaomi/apollo/lineage_apollo.mk device/xiaomi/apollo/gapps.txt && \

echo "===== Handling Gapps Output ====="
mv out/target/product/apollo out/target/product/gapps && \

# --- MicroG Build ---
echo "===== Setting up for MicroG Build ====="
mv device/xiaomi/apollo/microg.txt device/xiaomi/apollo/lineage_apollo.mk && \
make installclean && \
rise b && \
mv device/xiaomi/apollo/lineage_apollo.mk device/xiaomi/apollo/microg.txt && \

echo "===== Handling MicroG Output ====="
mv out/target/product/apollo out/target/product/microg && \

# --- Restore Vanilla ---
mv device/xiaomi/apollo/vanilla.txt device/xiaomi/apollo/lineage_apollo.mk && \

echo "===== All builds completed successfully! ====="
