#!/bin/bash

# ==========================================
# 📝 Setup Full-Script Logging & Telegram
# ==========================================
ROM_NAME="Cr"
DEVICE="apollo"
START_TIME=$(date +%s)
LOG_FILE="build_${ROM_NAME}_$(date +%Y%m%d_%H%M).log"
rm -f "/tmp/build_failed.lock"

exec 3>&1 4>&2
exec 1> >(tee -a "$LOG_FILE") 2>&1

TELEGRAM_TOKEN="${TELEGRAM_TOKEN}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"

if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "⚠️ Warning: TELEGRAM_TOKEN or TELEGRAM_CHAT_ID is not set in the environment."
fi

set -eE
set -o pipefail

send_tg_msg() {
    local MESSAGE="$1"
    local RES
    RES=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"         -d "chat_id=${TELEGRAM_CHAT_ID}"         -d "parse_mode=HTML"         -d "text=${MESSAGE}")
    if command -v jq &> /dev/null; then
        echo "$RES" | jq -r '.result.message_id' || true
    else
        echo "$RES" | python3 -c "import sys, json; print(json.load(sys.stdin).get('result', {}).get('message_id', ''))" 2>/dev/null || true
    fi
}

edit_tg_msg() {
    local MSG_ID="$1"
    local MESSAGE="$2"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/editMessageText"         -d "chat_id=${TELEGRAM_CHAT_ID}"         -d "message_id=${MSG_ID}"         -d "parse_mode=HTML"         -d "text=${MESSAGE}" > /dev/null || true
}

get_build_stats() {
    grep -oE '\[[0-9]+/[0-9]+\]' "$LOG_FILE" 2>/dev/null | tail -1 | tr -d '[]' || true
}

start_build_tracker() {
    local MSG_ID="$1"
    local ROM_NAME="$2"
    local DEVICE="$3"
    local STAGE="$4"
    
    (
        local LAST_PERCENT=-1
        while [ -f "/tmp/build_active_${DEVICE}" ] && kill -0 $$ 2>/dev/null; do
            local STATS
            STATS=$(get_build_stats)
            if [ -n "$STATS" ]; then
                local CURRENT=$(echo "$STATS" | cut -d'/' -f1)
                local TOTAL=$(echo "$STATS" | cut -d'/' -f2)
                if [ -n "$CURRENT" ] && [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
                    local PERCENT=$(( CURRENT * 100 / TOTAL ))
                    if [ "$PERCENT" -ne "$LAST_PERCENT" ]; then
                        LAST_PERCENT=$PERCENT
                        local NUM_BLOCKS=$(( PERCENT / 10 ))
                        local BAR=""
                        for ((i=0; i<10; i++)); do
                            if [ $i -lt $NUM_BLOCKS ]; then BAR="${BAR}█"; else BAR="${BAR}░"; fi
                        done
                        local UPDATE_TEXT="🔄 <b>BUILD IN PROGRESS</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Stage:</b> ${STAGE}%0A- <b>Progress:</b> [${BAR}] ${PERCENT}% (${CURRENT}/${TOTAL})"
                        edit_tg_msg "$MSG_ID" "$UPDATE_TEXT"
                    fi
                fi
            fi
            sleep 20
        done
    ) &
    TRACKER_PID=$!
}

handle_error() {
    trap - ERR
    set +eE
    set +o pipefail
    local FAILED_LINE="$1"
    exec 1>&3 2>&4
    sleep 1

    rm -f "/tmp/build_active_${DEVICE}"
    if [ -n "$TRACKER_PID" ]; then kill "$TRACKER_PID" 2>/dev/null || true; fi

    if [ -f "/tmp/build_failed.lock" ]; then exit 1; fi
    touch "/tmp/build_failed.lock"

    echo "❌ CRITICAL: Build failed on line $FAILED_LINE!"

    local BUILD_STATS
    BUILD_STATS=$(get_build_stats)

    local LOG_LINK=""
    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        if command -v gzip &> /dev/null; then gzip -9 "$LOG_FILE"; LOG_FILE="${LOG_FILE}.gz"; fi
        if ! command -v jq &> /dev/null; then sudo apt-get install -y jq > /dev/null 2>&1 || true; fi
        if command -v jq &> /dev/null; then
            local SERVER=$(curl -s --connect-timeout 30 --max-time 900 https://api.gofile.io/servers | jq -r '.data.servers[0].name' || true)
            if [ -n "$SERVER" ] && [ "$SERVER" != "null" ]; then
                local UPLOAD_RES=$(curl -L --connect-timeout 30 --max-time 900 --retry 3 -F "file=@${LOG_FILE}" "https://${SERVER}.gofile.io/contents/uploadfile" 2>&1 || true)
                local STATUS=$(echo "$UPLOAD_RES" | jq -r '.status' || true)
                if [ "$STATUS" == "ok" ]; then LOG_LINK=$(echo "$UPLOAD_RES" | jq -r '.data.downloadPage' || true); fi
            fi
        fi
    fi

    local END_TIME=$(date +%s)
    local ELAPSED_MINUTES=$(((END_TIME - START_TIME) / 60))
    local FAIL_MSG="❌ <b>BUILD FAILED</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Time:</b> ${ELAPSED_MINUTES}m%0A- <b>Error:</b> Line ${FAILED_LINE}"
    if [ -n "$BUILD_STATS" ]; then FAIL_MSG="${FAIL_MSG}%0A- <b>Build Stats:</b> ${BUILD_STATS} actions"; fi
    if [ -n "$LOG_LINK" ]; then FAIL_MSG="${FAIL_MSG}%0A- 📄 <a href="${LOG_LINK}" >View Crash Log</a>"; fi
    edit_tg_msg "$START_MSG_ID" "$FAIL_MSG"
    exit 1
}

trap 'handle_error $LINENO' ERR

START_MSG="🔄 <b>BUILD STARTED</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Host:</b> $(hostname)"
START_MSG_ID=$(send_tg_msg "$START_MSG")



# =============================
#   CrDroid Build Script
#   For: Vanilla
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Remove Device Settings --- (Reason: It Will fail sync when we re run this script)
rm -rf packages/resources/devicesettings

# --- Init ROM repo ---
repo init --depth=1 -u https://github.com/crdroidandroid/android.git -b 16.0 --git-lfs && \

# --- Sync ROM ---
/opt/crave/resync.sh && \
#repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune && \

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/device_xiaomi_apollo -b crdroid device/xiaomi/apollo && \

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
#git clone https://github.com/Evolution-X-Devices/hardware_xiaomi -b bka hardware/xiaomi && \

# --- Dolby ---
rm -rf hardware/dolby
#git clone https://github.com/Mi-Apollo/hardware_dolby -b moto-1.0 hardware/dolby && \
git clone https://github.com/Mi-Apollo/lunaris2_hardware_dolby -b 16 hardware/dolby && \

# --- Device Settings ---
rm -rf packages/resources/devicesettings
git clone https://github.com/Mi-Apollo/android_packages_resources_devicesettings -b lineage-23.2 packages/resources/devicesettings && \

# Private Keys
rm -rf vendor/lineage-priv/keys
git clone https://github.com/MurtazaKolachi/keys -b main vendor/lineage-priv/keys && \

# WFD repos
# git clone https://github.com/PocoF3Releases/device_qcom_wfd device/qcom/wfd && \
# git clone https://github.com/PocoF3Releases/vendor_qcom_wfd vendor/qcom/wfd && \

# =============================
#  Build: Vanilla
# =============================

# --- Vanilla Build ---
echo "===== Starting Vanilla Build ====="
touch "/tmp/build_active_apollo"
start_build_tracker "$START_MSG_ID" "$ROM_NAME" "$DEVICE" "Vanilla Build"

set +e
. build/envsetup.sh && \
breakfast apollo user && \
make installclean && \
mka bacon
BUILD_EXIT_CODE=$?
set -e

rm -f "/tmp/build_active_apollo"
kill "$TRACKER_PID" 2>/dev/null || true

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    exit $BUILD_EXIT_CODE
fi

echo "===== All builds completed successfully! ====="



crave run --no-patch -- ". build/envsetup.sh && \
breakfast apollo user && \
make installclean && \
mka bacon"

crave run --no-patch -- "rm -rf device/xiaomi && \
git clone https://github.com/MurtazaKolachi/device_xiaomi_apollo -b crdroid device/xiaomi/apollo && \
. build/envsetup.sh && \
breakfast apollo user && \
make installclean && \
mka bacon"

BUILD_STATS=$(get_build_stats)


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

    # Use robust globbing to find the ZIP file
    ZIPS=(${TARGET_DIR}/*apollo*.zip)
    if [ -f "${ZIPS[0]}" ]; then
        ROM_ZIP=$(ls -t "${TARGET_DIR}"/*apollo*.zip 2>/dev/null | head -n 1 || true)
        if [ -n "$ROM_ZIP" ] && [ -f "$ROM_ZIP" ]; then
            FILES_TO_UPLOAD+=("$ROM_ZIP")
            for JSON_FILE in "${TARGET_DIR}"/*.json; do
                if [ -f "$JSON_FILE" ]; then FILES_TO_UPLOAD+=("$JSON_FILE"); fi
            done
        fi
    fi
done

if [ ${#FILES_TO_UPLOAD[@]} -gt 0 ]; then
    SERVER=$(curl -s --connect-timeout 30 --max-time 900 https://api.gofile.io/servers | jq -r '.data.servers[0].name' || true)
    if [ -n "$SERVER" ] && [ "$SERVER" != "null" ]; then

        MASTER_LINK=""
        GUEST_TOKEN=""
        FOLDER_ID=""
        UPLOAD_FAILED=0

                for FILE_PATH in "${FILES_TO_UPLOAD[@]}"; do
            echo "📤 Uploading $(basename "$FILE_PATH")..."
            
            # Update Telegram to show which file is uploading
            local UPLOAD_MSG="📤 <b>UPLOADING ARTIFACTS</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>File:</b> $(basename "$FILE_PATH")"
            edit_tg_msg "$START_MSG_ID" "$UPLOAD_MSG"

            if [ -n "$GUEST_TOKEN" ] && [ -n "$FOLDER_ID" ]; then
                UPLOAD_RES=$(curl -L --connect-timeout 30 --max-time 900 --retry 3 -F "token=$GUEST_TOKEN" -F "folderId=$FOLDER_ID" -F "file=@${FILE_PATH}" "https://${SERVER}.gofile.io/contents/uploadfile" 2>/dev/null || true)
            else
                UPLOAD_RES=$(curl -L --connect-timeout 30 --max-time 900 --retry 3 -F "file=@${FILE_PATH}" "https://${SERVER}.gofile.io/contents/uploadfile" 2>/dev/null || true)
            fi

            STATUS=$(echo "$UPLOAD_RES" | jq -r '.status' 2>/dev/null || true)
            if [ -z "$STATUS" ] && command -v python3 &>/dev/null; then
                STATUS=$(echo "$UPLOAD_RES" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', ''))" 2>/dev/null || true)
            fi

            if [ "$STATUS" == "ok" ]; then
                echo "✅ Successfully uploaded $(basename "$FILE_PATH")"
                if [ -z "$GUEST_TOKEN" ]; then
                    MASTER_LINK=$(echo "$UPLOAD_RES" | jq -r '.data.downloadPage' 2>/dev/null || true)
                    if [ -z "$MASTER_LINK" ] && command -v python3 &>/dev/null; then
                        MASTER_LINK=$(echo "$UPLOAD_RES" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('downloadPage', ''))" 2>/dev/null || true)
                    fi
                    
                    GUEST_TOKEN=$(echo "$UPLOAD_RES" | jq -r '.data.guestToken' 2>/dev/null || true)
                    if [ -z "$GUEST_TOKEN" ] && command -v python3 &>/dev/null; then
                        GUEST_TOKEN=$(echo "$UPLOAD_RES" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('guestToken', ''))" 2>/dev/null || true)
                    fi

                    FOLDER_ID=$(echo "$UPLOAD_RES" | jq -r '.data.parentFolder' 2>/dev/null || true)
                    if [ -z "$FOLDER_ID" ] && command -v python3 &>/dev/null; then
                        FOLDER_ID=$(echo "$UPLOAD_RES" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('parentFolder', ''))" 2>/dev/null || true)
                    fi
                fi
            else
                echo "❌ Failed to upload $(basename "$FILE_PATH"). Response: $UPLOAD_RES"
                if [[ "$FILE_PATH" == *.zip ]]; then
                    UPLOAD_FAILED=1
                fi
            fi
        done

        if [ "$UPLOAD_FAILED" -eq 0 ] && [ -n "$MASTER_LINK" ]; then
            END_TIME=$(date +%s)
            ELAPSED_MINUTES=$(((END_TIME - START_TIME) / 60))
            SUCCESS_MSG="🚀 <b>BUILD SUCCESSFUL</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Time:</b> ${ELAPSED_MINUTES}m"
            if [ -n "$BUILD_STATS" ]; then SUCCESS_MSG="${SUCCESS_MSG}%0A- <b>Build Stats:</b> ${BUILD_STATS} actions"; fi
            SUCCESS_MSG="${SUCCESS_MSG}%0A- 🔗 <a href=\"${MASTER_LINK}\" >Download on Gofile</a>"
            edit_tg_msg "$START_MSG_ID" "$SUCCESS_MSG"
        else
            echo "❌ ROM upload failed or no master link generated."
            END_TIME=$(date +%s)
            ELAPSED_MINUTES=$(((END_TIME - START_TIME) / 60))
            FAIL_MSG="❌ <b>UPLOAD FAILED</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Time:</b> ${ELAPSED_MINUTES}m%0A- <b>Error:</b> ROM zip upload to Gofile failed"
            edit_tg_msg "$START_MSG_ID" "$FAIL_MSG"
        fi
    fi
fi

exec 1>&3 2>&4
sleep 1
if [ -f "$LOG_FILE" ] && command -v gzip &> /dev/null; then gzip -9 "$LOG_FILE"; fi
