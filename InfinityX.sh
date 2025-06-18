#! /bin/bash

rm -rf .repo/local_manifests; \
rm -rf {device,vendor,kernel,hardware}/xiaomi; \
repo init --depth=1 --no-repo-verify -u https://github.com/ProjectInfinity-X/manifest -b 15 --git-lfs -g default,-mips,-darwin,-notdefault && \
/opt/crave/resync.sh && \
git clone https://github.com/MurtazaKolachi/android_device_xiaomi_apollo -b infinity device/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/android_vendor_xiaomi_apollo -b new vendor/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/android_kernel_xiaomi_apollo -b main kernel/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/hardware_xiaomi -b fifteen hardware/xiaomi && \
rm -rf hardware/dolby && \
git clone https://github.com/MurtazaKolachi/hardware_dolby -b sony-1.3 hardware/dolby && \
rm -rf packages/apps/ViPER4AndroidFX && \
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \
rm -rf packages/resources/devicesettings && \
git clone https://github.com/PocoF3Releases/packages_resources_devicesettings -b aosp-15 packages/resources/devicesettings && \
export BUILD_USERNAME=Murtaza; \
export BUILD_HOSTNAME=crave; \
export TZ=Asia/Karachi; \
# Vanilla Build
. build/envsetup.sh && \
lunch infinity_apollo-user && make installclean && mka bacon; \
rm -rf out/target/product/vanilla && rm -rf out/target/product/gapps; \
cd out/target/product && mv apollo vanilla && cd ../../..; \
# Gapps Build
cd device/xiaomi/apollo && rm infinity_apollo.mk && mv gapps.txt infinity_apollo.mk && cd ../../..; \
. build/envsetup.sh; \
lunch infinity_apollo-user && make installclean && mka bacon; \
cd out/target/product && mv apollo gapps && cd ../../..; \