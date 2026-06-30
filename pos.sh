#!/bin/bash

# ==========================================
# 📝 Setup Full-Script Logging & Telegram
# ==========================================
ROM_NAME="Pos"
DEVICE="apollo"
START_TIME=$(date +%s)
LOG_FILE="build_${ROM_NAME}_$(date +%Y%m%d_%H%M).log"
rm -f "/tmp/build_failed.lock"

exec 3>&1 4>&2
exec 1> >(tee -a "$LOG_FILE") 2>&1

TELEGRAM_TOKEN="8097599295:AAGeJb1vic5nPFQQq6eDnX3KXKsx1eRK564"
TELEGRAM_CHAT_ID="1135559189"

set -eE
set -o pipefail

send_tg_msg() {
    local MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"         -d "chat_id=${TELEGRAM_CHAT_ID}"         -d "parse_mode=HTML"         -d "text=${MESSAGE}" > /dev/null
}

handle_error() {
    trap - ERR
    set +eE
    set +o pipefail
    local FAILED_LINE="$1"
    exec 1>&3 2>&4
    sleep 1

    if [ -f "/tmp/build_failed.lock" ]; then exit 1; fi
    touch "/tmp/build_failed.lock"

    echo "❌ CRITICAL: Build failed on line $FAILED_LINE!"

    local LOG_LINK=""
    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        if command -v gzip &> /dev/null; then gzip -9 "$LOG_FILE"; LOG_FILE="${LOG_FILE}.gz"; fi
        if ! command -v jq &> /dev/null; then sudo apt-get install -y jq > /dev/null 2>&1 || true; fi
        if command -v jq &> /dev/null; then
            local SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name' || true)
            if [ -n "$SERVER" ] && [ "$SERVER" != "null" ]; then
                local UPLOAD_RES=$(curl -s -F "file=@${LOG_FILE}" "https://${SERVER}.gofile.io/contents/uploadfile" || true)
                local STATUS=$(echo "$UPLOAD_RES" | jq -r '.status' || true)
                if [ "$STATUS" == "ok" ]; then LOG_LINK=$(echo "$UPLOAD_RES" | jq -r '.data.downloadPage' || true); fi
            fi
        fi
    fi

    local END_TIME=$(date +%s)
    local ELAPSED_MINUTES=$(((END_TIME - START_TIME) / 60))
    local FAIL_MSG="BUILD FAILED ❌%0A├─ 📱 <b>Device:</b> ${DEVICE}%0A├─ 💿 <b>ROM:</b> ${ROM_NAME}%0A├─ ⏱️ <b>Time:</b> ${ELAPSED_MINUTES}m%0A├─ ⚠️ <b>Error:</b> Line ${FAILED_LINE}"
    if [ -n "$LOG_LINK" ]; then FAIL_MSG="${FAIL_MSG}%0A└─ 📄 <a href="${LOG_LINK}">View Crash Log</a>"; fi
    send_tg_msg "$FAIL_MSG"
    exit 1
}

trap 'handle_error $LINENO' ERR

START_MSG="BUILD STARTED ⏳%0A├─ 📱 <b>Device:</b> ${DEVICE}%0A├─ 💿 <b>ROM:</b> ${ROM_NAME}%0A└─ 💻 <b>Host:</b> $(hostname)"
send_tg_msg "$START_MSG"



# =============================
#  PixelOS Build Script
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Remove Device Settings --- (Reason: It Will fail sync when we re run this script)
rm -rf packages/resources/devicesettings

# --- Init ROM repo ---
repo init --depth=1 -u https://github.com/PixelOS-AOSP/android_manifest -b sixteen-qpr2 --git-lfs

# --- Sync ROM ---
#/opt/crave/resync.sh && \
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune --optimized-fetch --prune

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/device_xiaomi_apollo -b pos device/xiaomi/apollo && \

# --- Clone Vendor Tree ---
rm -rf vendor/xiaomi
git clone https://github.com/MurtazaKolachi/vendor_xiaomi_apollo -b 16 vendor/xiaomi/apollo && \

# --- Clone Kernel Tree ---
rm -rf kernel/xiaomi
git clone --recurse-submodules https://github.com/MurtazaKolachi/kernel_xiaomi_apollo -b 16 kernel/xiaomi/apollo && \
#git clone https://github.com/MurtazaKolachi/android_kernel_xiaomi_apollo -b staging kernel/xiaomi/apollo && \

# --- Clone Hardware Tree ---
rm -rf hardware/xiaomi
git clone https://github.com/LineageOS/android_hardware_xiaomi -b lineage-23.2 hardware/xiaomi && \
#git clone https://github.com/Evolution-X-Devices/hardware_xiaomi -b bka hardware/xiaomi && \ && \
rm -rf hardware/xiaomi/megvii

# --- Dolby ---
rm -rf hardware/dolby
#git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \
git clone https://github.com/Mi-Apollo/lunaris2_hardware_dolby -b 16 hardware/dolby && \

# --- Device Settings ---
rm -rf packages/resources/devicesettings
git clone https://github.com/Mi-Apollo/android_packages_resources_devicesettings -b lineage-23.2 packages/resources/devicesettings

# Private Keys
rm -rf vendor/lineage-priv/keys
git clone https://github.com/MurtazaKolachi/keys -b main vendor/lineage-priv/keys && \

# =============================
#  Build Environment Setup
# =============================

# --- Start Build ---
echo "===== Starting Vanilla Build ====="
. build/envsetup.sh && \
breakfast apollo userdebug && \
make installclean && \
m pixelos

echo "===== Build completed successfully! ====="


# ==========================================
# ☁️ Process Artifacts & Upload
# ==========================================
echo "=========================================="
echo "☁️ Preparing files for Gofile upload..."

if ! command -v jq &> /dev/null; then sudo apt-get install -y jq > /dev/null; fi

FILES_TO_UPLOAD=()

for BUILD_TYPE in "vanilla" "gapps" "apollo"; do
    TARGET_DIR="out/target/product/${BUILD_TYPE}"
    if [ ! -d "$TARGET_DIR" ]; then continue; fi

    ROM_ZIP=$(ls -t ${TARGET_DIR}/*apollo*.zip 2>/dev/null | head -n 1 || true)
    if [ -n "$ROM_ZIP" ] && [ -f "$ROM_ZIP" ]; then
        FILES_TO_UPLOAD+=("$ROM_ZIP")
        for IMG in boot.img dtb.img dtbo.img vendor_boot.img; do
            if [ -f "${TARGET_DIR}/$IMG" ]; then FILES_TO_UPLOAD+=("${TARGET_DIR}/$IMG"); fi
        done
        for JSON_FILE in "${TARGET_DIR}"/*.json; do
            if [ -f "$JSON_FILE" ]; then FILES_TO_UPLOAD+=("$JSON_FILE"); fi
        done
    fi
done

if [ ${#FILES_TO_UPLOAD[@]} -gt 0 ]; then
    SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name' || true)
    if [ -n "$SERVER" ] && [ "$SERVER" != "null" ]; then
        MASTER_LINK=""
        GUEST_TOKEN=""
        FOLDER_ID=""

        for FILE_PATH in "${FILES_TO_UPLOAD[@]}"; do
            if [ -n "$GUEST_TOKEN" ] && [ -n "$FOLDER_ID" ]; then
                UPLOAD_RES=$(curl -s --retry 3 -F "token=$GUEST_TOKEN" -F "folderId=$FOLDER_ID" -F "file=@${FILE_PATH}" "https://${SERVER}.gofile.io/contents/uploadfile" || true)
            else
                UPLOAD_RES=$(curl -s --retry 3 -F "file=@${FILE_PATH}" "https://${SERVER}.gofile.io/contents/uploadfile" || true)
            fi

            STATUS=$(echo "$UPLOAD_RES" | jq -r '.status' || true)
            if [ "$STATUS" == "ok" ] && [ -z "$GUEST_TOKEN" ]; then
                MASTER_LINK=$(echo "$UPLOAD_RES" | jq -r '.data.downloadPage' || true)
                GUEST_TOKEN=$(echo "$UPLOAD_RES" | jq -r '.data.guestToken' || true)
                FOLDER_ID=$(echo "$UPLOAD_RES" | jq -r '.data.parentFolder' || true)
            fi
        done

        if [ -n "$MASTER_LINK" ]; then
            END_TIME=$(date +%s)
            ELAPSED_MINUTES=$(((END_TIME - START_TIME) / 60))
            SUCCESS_MSG="BUILD SUCCESSFUL 🚀%0A├─ 📱 <b>Device:</b> ${DEVICE}%0A├─ 💿 <b>ROM:</b> ${ROM_NAME}%0A├─ ⏱️ <b>Time:</b> ${ELAPSED_MINUTES}m%0A└─ 🔗 <a href="${MASTER_LINK}">Download on Gofile</a>"
            send_tg_msg "$SUCCESS_MSG"
        fi
    fi
else
    echo "❌ No build artifacts found to upload."
    END_TIME=$(date +%s)
    ELAPSED_MINUTES=$(((END_TIME - START_TIME) / 60))
    FAIL_MSG="BUILD FAILED ❌%0A├─ 📱 <b>Device:</b> ${DEVICE}%0A├─ 💿 <b>ROM:</b> ${ROM_NAME}%0A├─ ⏱️ <b>Time:</b> ${ELAPSED_MINUTES}m%0A└─ ⚠️ <b>Error:</b> No zip generated"
    send_tg_msg "$FAIL_MSG"
fi

exec 1>&3 2>&4
sleep 1
if [ -f "$LOG_FILE" ] && command -v gzip &> /dev/null; then gzip -9 "$LOG_FILE"; fi
