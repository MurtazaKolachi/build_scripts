#! /bin/bash

rm -rf .repo/local_manifests; \
rm -rf {device,vendor,kernel,hardware}/xiaomi; \
repo init --depth=1 --no-repo-verify -u https://github.com/RisingOS-Revived/android -b qpr2 -g default,-mips,-darwin,-notdefault && \
/opt/crave/resync.sh && \
git clone https://github.com/RisingOS-Revived-devices/device_xiaomi_apollo -b fifteen device/xiaomi/apollo && \
git clone https://github.com/RisingOS-Revived-devices/vendor_xiaomi_apollo -b fifteen vendor/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/android_kernel_xiaomi_apollo -b main kernel/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/hardware_xiaomi -b fifteen hardware/xiaomi && \
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