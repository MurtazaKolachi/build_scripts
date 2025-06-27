#! /bin/bash

rm -rf .repo/local_manifests; \
rm -rf {device,vendor,kernel,hardware}/xiaomi; \
repo init --depth=1 --no-repo-verify -u https://github.com/AxionAOSP/android -b lineage-22.2 --git-lfs -g default,-mips,-darwin,-notdefault && \
/opt/crave/resync.sh && \
git clone https://github.com/MurtazaKolachi/android_device_xiaomi_apollo -b test device/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/android_vendor_xiaomi_apollo -b test vendor/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b main kernel/xiaomi/apollo && \
git clone https://github.com/LineageOS/android_hardware_xiaomi/ -b lineage-23.0 hardware/xiaomi && \
rm -rf hardware/dolby && \
git clone https://github.com/Matrixx-Devices/hardware_dolby -b sony-1.3 hardware/dolby && \
rm -rf packages/apps/ViPER4AndroidFX && \
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \
rm -rf packages/resources/devicesettings && \
git clone https://github.com/PocoF3Releases/packages_resources_devicesettings -b aosp-15 packages/resources/devicesettings && \
/opt/crave/resync.sh && \
export BUILD_USERNAME=Murtaza; \
export BUILD_HOSTNAME=crave; \
export TZ=Asia/Karachi; \
# Vanilla Build
. build/envsetup.sh && \
gk -s && axion apollo va user && make installclean && ax -br
