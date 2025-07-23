#! /bin/bash

# Remove Manifests
#rm -rf .repo/local_manifests

# ROM Repo
repo init --depth=1 --no-repo-verify -u https://github.com/Mi-Apollo/cr_android -b 15.0 --git-lfs -g default,-mips,-darwin,-notdefault && \

# Sync Rom
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags && \

# Trees

# Device Tree
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/android_device_xiaomi_apollo -b cr device/xiaomi/apollo && \

# Leica DT
git clone https://github.com/MurtazaKolachi/device_xiaomi_camera -b main device/xiaomi/camera && \

# Vendor Tree
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/android_vendor_xiaomi_apollo -b 15.0 vendor/xiaomi/apollo && \

# Leica VT
git clone https://gitlab.com/murtazakolachi/vendor_xiaomi_camera -b aosp-15-apollo vendor/xiaomi/camera && \

# Kernel Tree
rm -rf kernel/xiaomi
git clone https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b main kernel/xiaomi/apollo && \

# Hardware Tree
rm -rf hardware/xiaomi
git clone https://github.com/Evolution-X-Devices/hardware_xiaomi -b bka hardware/xiaomi && \

# Dolby
rm -rf hardware/dolby
git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \

# ViPER
rm -rf packages/apps/ViPER4AndroidFX
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \

# Other
rm -rf packages/resources/devicesettings
git clone https://github.com/PocoF3Releases/packages_resources_devicesettings -b aosp-16 packages/resources/devicesettings && \


# --- Setup Build Environment ---
export BUILD_USERNAME=Murtaza
export BUILD_HOSTNAME=Eclipse
export TZ=Asia/Karachi

# --- Build ---
. build/envsetup.sh && \
breakfast apollo user && make installclean && mka bacon
