#! /bin/bash

rm -rf .repo/local_manifests; \
rm -rf {device,vendor,kernel,hardware}/xiaomi; \
rm -rf packages/apps/ViPER4AndroidFX && \
repo init --depth=1 --no-repo-verify -u https://github.com/RisingOS-Revived/android -b qpr2 -g default,-mips,-darwin,-notdefault && \
/opt/crave/resync.sh && \
git clone https://github.com/RisingOS-Revived-devices/device_xiaomi_apollo -b fifteen device/xiaomi/apollo && \
git clone https://github.com/RisingOS-Revived-devices/vendor_xiaomi_apollo -b fifteen vendor/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/android_kernel_xiaomi_apollo -b main kernel/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/hardware_xiaomi -b fifteen hardware/xiaomi && \
rm -rf hardware/dolby && \
git clone https://github.com/MurtazaKolachi/hardware_dolby -b sony-1.3 hardware/dolby && \
rm -rf packages/apps/ViPER4AndroidFX && \
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \
rm -rf packages/resources/devicesettings && \
git clone https://github.com/PocoF3Releases/packages_resources_devicesettings -b aosp-15 packages/resources/devicesettings && \
git clone https://github.com/MurtazaKolachi/keys.git -b rising vendor/lineage-priv/keys && \
export BUILD_USERNAME=Murtaza; \
export BUILD_HOSTNAME=crave; \
export TZ=Asia/Karachi; \
# Vanilla Build
. build/envsetup.sh && \
riseup apollo user && make installclean && rise b; \
rm -rf out/target/product/vanilla && rm -rf out/target/product/gapps; \
cd out/target/product && mv apollo vanilla && cd ../../..; \
# Gapps Build
cd device/xiaomi/apollo && rm lineage_apollo.mk && mv gapps.txt lineage_apollo.mk && cd ../../..; \
. build/envsetup.sh; \
riseup apollo user && make installclean && rise b; \
cd out/target/product && mv apollo gapps && cd ../../..; \