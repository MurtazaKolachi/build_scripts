#! /bin/bash

rm -rf .repo/local_manifests; \
rm -rf {device,vendor,kernel,hardware}/xiaomi; \
repo init --depth=1 --no-repo-verify -u https://github.com/AxionAOSP/android -b lineage-22.2 --git-lfs -g default,-mips,-darwin,-notdefault && \
/opt/crave/resync.sh && \
git clone https://github.com/MurtazaKolachi/android_device_xiaomi_apollo -b axion device/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/android_vendor_xiaomi_apollo -b main vendor/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/android_kernel_xiaomi_apollo -b main kernel/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/hardware_xiaomi -b fifteen hardware/xiaomi && \
/opt/crave/resync.sh && \
export BUILD_USERNAME=Murtaza; \
export BUILD_HOSTNAME=crave; \
export TZ=Asia/Karachi; \
. build/envsetup.sh && \
breakfast apollo user && make installclean && mka bacon