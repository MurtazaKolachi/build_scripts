#!/bin/bash

# =============================
#   InfinityX Build Script
#   For: Vanilla → Gapps
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Init ROM repo ---
repo init -u https://github.com/VoltageOS/manifest.git -b 16 --git-lfs && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/device_xiaomi_apollo -b 16 device/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/device_xiaomi_sm8250-common -b bak device/xiaomi/sm8250-common && \

# --- Clone Vendor Tree ---
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/vendor_xiaomi_apollo -b 16 vendor/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/vendor_xiaomi_sm8250-common -b 16 vendor/xiaomi/sm8250-common && \

# --- Clone Kernel Tree ---
rm -rf kernel/xiaomi
git clone https://github.com/MurtazaKolachi/android_kernel_xiaomi_apollo -b staging kernel/xiaomi/sm8250 && \

# --- Clone Hardware Tree ---
rm -rf hardware/xiaomi
git clone https://github.com/LineageOS/android_hardware_xiaomi -b lineage-23.0 hardware/xiaomi && \

# --- ViPER ---
rm -rf packages/apps/ViPER4AndroidFX
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \

# --- Device Settings ---
rm -rf packages/resources/devicesettings
git clone https://github.com/PocoF3Releases/packages_resources_devicesettings -b aosp-16 packages/resources/devicesettings && \

# Private Keys
rm -rf vendor/voltage-priv/keys
git clone https://github.com/MurtazaKolachi/keys -b voltage vendor/voltage-priv/keys && \

# =============================
#  Build: Vanilla → Gapps
# =============================

# --- Vanilla Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
breakfast apollo user && \
make installclean && \
mka bacon