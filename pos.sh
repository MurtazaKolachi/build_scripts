#!/bin/bash

# =============================
#  PixelOS Build Script
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Init ROM repo ---
repo init -u https://github.com/PixelOS-AOSP/manifest.git -b fifteen --git-lfs && \
repo init -u https://github.com/PixelOS-AOSP/android_manifest -b sixteen --git-lfs

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/android_device_xiaomi_apollo -b pos15 device/xiaomi/apollo && \

# --- Clone Vendor Tree ---
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/android_vendor_xiaomi_apollo -b 15 vendor/xiaomi/apollo && \

# --- Clone Kernel Tree ---
rm -rf kernel/xiaomi
git clone https://github.com/MurtazaKolachi/android_kernel_xiaomi_apollo -b staging kernel/xiaomi/apollo && \

# --- Clone Hardware Tree ---
rm -rf hardware/xiaomi
git clone https://github.com/Mi-Apollo/hardware_xiaomi -b fifteen hardware/xiaomi && \

# --- Dolby ---
rm -rf hardware/dolby
git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \

# --- ViPER ---
rm -rf packages/apps/ViPER4AndroidFX
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \

# --- Device Settings ---
rm -rf packages/resources/devicesettings
git clone https://github.com/PocoF3Releases/packages_resources_devicesettings -b aosp-15 packages/resources/devicesettings

# =============================
#  Build Environment Setup
# =============================

# --- Start Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
lunch aosp_apollo-bp1a-user && \
make installclean && \
mka bacon

echo "===== Build completed successfully! ====="

internal error: could not open symlink hardware/qcom/sm8150/Android.bp; its target (gps/os_pickup.bp) cannot be opened
internal error: could not open symlink hardware/qcom/sdm845/Android.bp; its target (gps/os_pickup.bp) cannot be opened
internal error: could not open symlink hardware/qcom/sm7250/Android.bp; its target (gps/os_pickup.bp) cannot be opened


rm -rf hardware/qcom/sdm845/gps
rm -rf hardware/qcom/sm8150/gps
rm -rf hardware/qcom/sm7250/gps
git clone https://github.com/LineageOS/android_hardware_qcom_sdm845_gps hardware/qcom/sdm845/gps
git clone https://github.com/LineageOS/android_hardware_qcom_sm8150_gps hardware/qcom/sm8150/gps
git clone https://github.com/LineageOS/android_hardware_qcom_sm7250_gps hardware/qcom/sm7250/gps
cd hardware/qcom/sdm845/gps && git revert 33255a114acd33d967031ab48792b5c3bae01f5b..71438e3fa19861a7fee23ea8a26f1ac6c90c5f85 && cd ../../../..
cd hardware/qcom/sm8150/gps && git revert c102ecaf661265a5bb4bab028c4dba8454016e1b && cd ../../../..
cd hardware/qcom/sm7250/gps && git revert c0e0375f06c0335062f19e3d87cb84d3c27cbc57 && cd ../../../..

rm -rf hardware/qcom/sdm845/display
rm -rf hardware/qcom/sm8150/display
rm -rf hardware/qcom/sm7250/display
git clone https://github.com/LineageOS/android_hardware_qcom_sdm845_display hardware/qcom/sdm845/display
git clone https://github.com/LineageOS/android_hardware_qcom_sm8150_display hardware/qcom/sm8150/display
git clone https://github.com/LineageOS/android_hardware_qcom_sm7250_display hardware/qcom/sm7250/display
cd hardware/qcom/sdm845/display && git revert a1cb4c2b9b83992962aac13384a2cd28aa677744..0d74c81f9b79a0a47ccffcb8598c3899b34f4278 && cd ../../../..
cd hardware/qcom/sm8150/display && git revert c13de989eb36bccdfaefb31c0071852e8a497ab4 && cd ../../../..
cd hardware/qcom/sm7250/display && git revert c0e0375f06c0335062f19e3d87cb84d3c27cbc57 && cd ../../../..

rm -rf packages/apps/ParanoidSense
git clone https://github.com/Mi-Apollo/packages_apps_ParanoidSense -b fifteen packages/apps/ParanoidSense


nano .repo/manifests/snippets/custom.xml