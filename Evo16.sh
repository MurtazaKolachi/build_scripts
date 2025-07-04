#! /bin/bash

rm -rf .repo/local_manifests; \
rm -rf {device,vendor,kernel,hardware}/xiaomi; \

# ==== Fix for Trusty Soong Error (dummy module define) ====

mkdir -p trusty/vendor/google/aosp/scripts/dummy

cat > trusty/vendor/google/aosp/scripts/Android.bp << 'EOF'
bootstrap_go_package {
    name: "trusty_dirgroup_prebuilts_clang_host_linux-x86",
    pkgPath: "trusty/vendor/google/aosp/scripts/dummy",
    deps: [],
    srcs: ["dummy.go"],
}
EOF

echo "package dummy" > trusty/vendor/google/aosp/scripts/dummy/dummy.go

# ==== End of Trusty Fix ====

repo init --depth=1 --no-repo-verify -u https://github.com/MurtazaKolachi/manifest -b bka --git-lfs -g default,-mips,-darwin,-notdefault && \
/opt/crave/resync.sh && \
git clone https://github.com/MurtazaKolachi/android_device_xiaomi_apollo -b evo device/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/android_vendor_xiaomi_apollo -b evo vendor/xiaomi/apollo && \
git clone https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b main kernel/xiaomi/apollo && \
git clone https://github.com/Evolution-X-Devices/hardware_xiaomi -b bka hardware/xiaomi && \
rm -rf packages/apps/ViPER4AndroidFX && \
git clone https://github.com/AxionAOSP/android_packages_apps_ViPER4AndroidFX -b v4a packages/apps/ViPER4AndroidFX && \
export BUILD_USERNAME=Murtaza; \
export BUILD_HOSTNAME=crave; \
export TZ=Asia/Karachi; \
# Vanilla Build
. build/envsetup.sh && \
lunch lineage_apollo-bp1a-user && make installclean && m evolution
