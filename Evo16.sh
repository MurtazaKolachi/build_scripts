#! /bin/bash

# Remove Manifests
rm -rf .repo/local_manifests

# ROM Repo
repo init --depth=1 --no-repo-verify -u https://github.com/Mi-Apollo/evo_manifest -b bka --git-lfs -g default,-mips,-darwin,-notdefault && \

# Sync Rom
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags && \

# Trees

# Device Tree
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/android_device_xiaomi_apollo -b evo device/xiaomi/apollo && \

# Leica DT
git clone https://github.com/MurtazaKolachi/device_xiaomi_camera -b main device/xiaomi/camera && \

# Vendor Tree
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/android_vendor_xiaomi_apollo -b 16.0 vendor/xiaomi/apollo && \

# Leica VT
git clone https://gitlab.com/murtazakolachi/vendor_xiaomi_camera -b aosp-15-apollo vendor/xiaomi/camera && \

# Kernel Tree
rm -rf kernel/xiaomi
git clone https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b main kernel/xiaomi/apollo && \

# Hardware Tree
rm -rf hardware/xiaomi
git clone https://github.com/LineageOS/android_hardware_xiaomi -b lineage-23.0 hardware/xiaomi && \

# Dolby
#rm -rf hardware/dolby
#git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \

# ViPER
#rm -rf packages/apps/ViPER4AndroidFX
#git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \

# Other
rm -rf packages/resources/devicesettings
git clone https://github.com/PocoF3Releases/packages_resources_devicesettings -b aosp-16 packages/resources/devicesettings && \


# --- Setup Build Environment ---
export BUILD_USERNAME=Murtaza
export BUILD_HOSTNAME=Eclipse
export TZ=Asia/Karachi

# --- Build ---
. build/envsetup.sh && \
lunch lineage_apollo-bp2a-user && \
make installclean && \
m evolution && \

# --- Handle Vanilla Output ---
echo "Handling Vanilla build output..."
mv out/target/product/apollo out/target/product/vanilla && \
echo "Vanilla build finished. Output is in out/target/product/vanilla"

# --- Gapps Build ---
echo "Setting up for Gapps Build..."
mv device/xiaomi/apollo/gapps.txt device/xiaomi/apollo/lineage_apollo.mk && \

echo "Starting Gapps Build..."
make installclean && \
m evolution && \

# --- Handle Gapps Output ---
echo "Handling Gapps build output..."
mv out/target/product/apollo out/target/product/gapps
echo "Gapps build finished. Output is in out/target/product/gapps"

# --- Build is Successful!! ---
echo "All builds completed successfully!"
