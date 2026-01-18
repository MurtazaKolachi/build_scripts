#!/bin/bash

# =============================
#   EvolutionX Build Script
#   For: Vanilla → Gapps
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Remove Device Settings --- (Reason: It Will fail sync when we re run this script)
rm -rf packages/resources/devicesettings

# --- Init ROM repo ---
repo init -u https://github.com/Mi-Apollo/evo_manifest.git -b bq2 --git-lfs && \

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/device_xiaomi_apollo -b evo device/xiaomi/apollo && \

# --- Clone Vendor Tree ---
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/vendor_xiaomi_apollo -b 16 vendor/xiaomi/apollo && \

# --- Clone Kernel Tree ---
rm -rf kernel/xiaomi
git clone https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b 16 kernel/xiaomi/apollo && \
#git clone https://github.com/MurtazaKolachi/android_kernel_xiaomi_apollo -b staging kernel/xiaomi/apollo && \

# --- Clone Hardware Tree ---
rm -rf hardware/xiaomi
git clone https://github.com/MurtazaKolachi/android_hardware_xiaomi -b lineage-23.0 hardware/xiaomi && \
#git clone https://github.com/Evolution-X-Devices/hardware_xiaomi -b bka hardware/xiaomi && \

# --- Dolby ---
rm -rf hardware/dolby
#git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \
git clone https://github.com/Mi-Apollo/lunaris2_hardware_dolby -b 16.0 hardware/dolby && \

# --- ViPER ---
rm -rf packages/apps/ViPER4AndroidFX
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \

# --- Device Settings ---
rm -rf packages/resources/devicesettings
git clone https://github.com/MurtazaKolachi/android_packages_resources_devicesettings -b lineage-23.0 packages/resources/devicesettings && \

# Private Keys
rm -rf vendor/evolution-priv/keys
git clone https://github.com/MurtazaKolachi/keys -b evo vendor/evolution-priv/keys && \

# WFD repos
# git clone https://github.com/PocoF3Releases/device_qcom_wfd device/qcom/wfd && \
# git clone https://github.com/PocoF3Releases/vendor_qcom_wfd vendor/qcom/wfd && \

# Remove output directories to be on safer side
rm -rf out/target/product/vanilla &&
rm -rf out/target/product/gapps &&

# =============================
#  Build: Vanilla → Gapps
# =============================

# --- Vanilla Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
lunch lineage_apollo-bp4a-user && \
make installclean && \
m evolution && \
mv device/xiaomi/apollo/lineage_apollo.mk device/xiaomi/apollo/vanilla.txt && \

echo "===== Handling Vanilla Output ====="
mv out/target/product/apollo out/target/product/vanilla && \

# --- Gapps Build ---
echo "===== Setting up for Gapps Build ====="
mv device/xiaomi/apollo/gapps.txt device/xiaomi/apollo/lineage_apollo.mk && \
make installclean && \
m evolution && \
mv device/xiaomi/apollo/lineage_apollo.mk device/xiaomi/apollo/gapps.txt && \

echo "===== Handling Gapps Output ====="
mv out/target/product/apollo out/target/product/gapps && \

# --- Restore Vanilla ---
mv device/xiaomi/apollo/vanilla.txt device/xiaomi/apollo/lineage_apollo.mk && \

echo "===== All builds completed successfully! ====="
