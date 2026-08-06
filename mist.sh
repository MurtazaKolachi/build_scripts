#!/bin/bash

# ==========================================
# 📝 Setup Full-Script Logging & Telegram
# ==========================================
ROM_NAME="Mist"
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
if ! command -v jq &> /dev/null; then
    mkdir -p ~/bin
    curl -L -s -o ~/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux64 2>/dev/null || true
    chmod +x ~/bin/jq 2>/dev/null || true
    export PATH=$HOME/bin:$PATH
fi

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

gofile_upload() {
    local FILE="$1"
    local GUEST_TOKEN="${2:-}"
    local FOLDER_ID="${3:-}"
    
    mapfile -t SERVERS < <(curl -s https://api.gofile.io/servers | jq -r '.data.servers[].name' 2>/dev/null)
    if [ ${#SERVERS[@]} -eq 0 ]; then
        return 1
    fi

    for S in $(printf "%s\n" "${SERVERS[@]}" | shuf); do
        local RESP
        if [ -n "$GUEST_TOKEN" ] && [ -n "$FOLDER_ID" ]; then
            RESP=$(curl -L --connect-timeout 30 --max-time 900 --retry 2 -F "token=$GUEST_TOKEN" -F "folderId=$FOLDER_ID" -F "file=@${FILE}" "https://${S}.gofile.io/contents/uploadfile" 2>/dev/null || true)
        else
            RESP=$(curl -L --connect-timeout 30 --max-time 900 --retry 2 -F "file=@${FILE}" "https://${S}.gofile.io/contents/uploadfile" 2>/dev/null || true)
        fi

        local STATUS=$(echo "$RESP" | jq -r '.status' 2>/dev/null || true)
        if [ "$STATUS" == "ok" ]; then
            echo "$RESP"
            return 0
        fi
    done
    return 1
}

pixeldrain_upload() {
    local FILE="$1"
    if [ -f "$FILE" ]; then
        local RESPONSE=$(curl -s -F "file=@$FILE" https://pixeldrain.com/api/file 2>/dev/null)
        local FILE_ID=$(echo "$RESPONSE" | jq -r '.id' 2>/dev/null)
        if [[ "$FILE_ID" != "null" && -n "$FILE_ID" ]]; then
            echo "https://pixeldrain.com/u/$FILE_ID"
            return 0
        fi
    fi
    return 1
}

get_sys_stats() {
    read -r _ u1 n1 s1 i1 w1 irq1 sirq1 st1 _ < /proc/stat
    sleep 1
    read -r _ u2 n2 s2 i2 w2 irq2 sirq2 st2 _ < /proc/stat
    idle1=$((i1 + w1)); idle2=$((i2 + w2))
    total1=$((u1 + n1 + s1 + i1 + w1 + irq1 + sirq1 + st1))
    total2=$((u2 + n2 + s2 + i2 + w2 + irq2 + sirq2 + st2))
    diff_idle=$((idle2 - idle1)); diff_total=$((total2 - total1))
    local CPU=0
    if [ "$diff_total" -gt 0 ]; then CPU=$(( 100 * (diff_total - diff_idle) / diff_total )); fi
    local MEM_USED=$(free -m | awk '/Mem:/ {printf "%.1f", $3/1024}')
    local MEM_TOTAL=$(free -m | awk '/Mem:/ {printf "%.1f", $2/1024}')
    local LOAD=$(cut -d' ' -f1 /proc/loadavg)
    echo "$CPU|$MEM_USED|$MEM_TOTAL|$LOAD"
}

send_tg_msg_with_button() {
    local MESSAGE="$1"
    local RES=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "parse_mode=HTML" \
        -d "text=${MESSAGE}" \
        -d 'reply_markup={"inline_keyboard":[[{"text":"🔄 Refresh Info","callback_data":"refresh"}]]}')
    echo "$RES" | jq -r '.result.message_id' 2>/dev/null || true
}

edit_tg_msg_with_button() {
    local MSG_ID="$1"
    local MESSAGE="$2"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/editMessageText" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "message_id=${MSG_ID}" \
        -d "parse_mode=HTML" \
        -d "text=${MESSAGE}" \
        -d 'reply_markup={"inline_keyboard":[[{"text":"🔄 Refresh Info","callback_data":"refresh"}]]}' > /dev/null 2>&1 || true
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
        local OFFSET=0
        local LAST_UPDATE=$(date +%s)

        while [ -f "/tmp/build_active_${DEVICE}" ] && kill -0 $$ 2>/dev/null; do
            local STATS=$(get_build_stats)
            local PROG_TEXT=""
            if [ -n "$STATS" ]; then
                local CURRENT=$(echo "$STATS" | cut -d'/' -f1)
                local TOTAL=$(echo "$STATS" | cut -d'/' -f2)
                if [ -n "$CURRENT" ] && [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
                    local PERCENT=$(( CURRENT * 100 / TOTAL ))
                    local NUM_BLOCKS=$(( PERCENT / 10 ))
                    local BAR=""
                    for ((i=0; i<10; i++)); do
                        if [ $i -lt $NUM_BLOCKS ]; then BAR="${BAR}█"; else BAR="${BAR}░"; fi
                    done
                    PROG_TEXT="%0A- <b>Progress:</b> [${BAR}] ${PERCENT}% (${CURRENT}/${TOTAL})"
                fi
            fi

            local REFRESH_PRESSED=0
            local UPDATES=$(curl -s --max-time 5 "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates?offset=${OFFSET}" 2>/dev/null || true)
            local COUNT=$(echo "$UPDATES" | jq '.result | length' 2>/dev/null || echo 0)
            if [ "$COUNT" -gt 0 ]; then
                for ((i=0; i<COUNT; i++)); do
                    local UPDATE=$(echo "$UPDATES" | jq -c ".result[$i]" 2>/dev/null)
                    local UPDATE_ID=$(echo "$UPDATE" | jq '.update_id' 2>/dev/null)
                    OFFSET=$((UPDATE_ID + 1))
                    local CALLBACK=$(echo "$UPDATE" | jq -r '.callback_query.data // empty' 2>/dev/null)
                    if [ "$CALLBACK" = "refresh" ]; then
                        local CB_ID=$(echo "$UPDATE" | jq -r '.callback_query.id // empty' 2>/dev/null)
                        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/answerCallbackQuery" -d "callback_query_id=${CB_ID}" > /dev/null 2>&1 || true
                        REFRESH_PRESSED=1
                    fi
                done
            fi

            local NOW=$(date +%s)
            if [ "$REFRESH_PRESSED" -eq 1 ] || [ $((NOW - LAST_UPDATE)) -ge 20 ]; then
                LAST_UPDATE=$NOW
                local SYS_STATS=$(get_sys_stats)
                local CPU=$(echo "$SYS_STATS" | cut -d'|' -f1)
                local MEM_U=$(echo "$SYS_STATS" | cut -d'|' -f2)
                local MEM_T=$(echo "$SYS_STATS" | cut -d'|' -f3)
                local LOAD=$(echo "$SYS_STATS" | cut -d'|' -f4)
                local CONSOLE=$(grep -v '^\s*$' "$LOG_FILE" 2>/dev/null | tail -n1 | cut -c1-100 | sed 's/[<>&]/_/g')

                local UPDATE_TEXT="🔄 <b>BUILD IN PROGRESS</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Stage:</b> ${STAGE}${PROG_TEXT}%0A- <b>CPU:</b> ${CPU}% | <b>RAM:</b> ${MEM_U}/${MEM_T} GB | <b>Load:</b> ${LOAD}%0A- <b>Console:</b> <code>${CONSOLE}</code>"
                edit_tg_msg_with_button "$MSG_ID" "$UPDATE_TEXT"
            fi
            sleep 3
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
    if [ -n "$TRACKER_PID" ]; then kill "$TRACKER_PID" 2>/dev/null || true; wait "$TRACKER_PID" 2>/dev/null || true; fi

    if [ -f "/tmp/build_failed.lock" ]; then exit 1; fi
    touch "/tmp/build_failed.lock"

    echo "❌ CRITICAL: Build failed on line $FAILED_LINE!"

    local BUILD_STATS
    BUILD_STATS=$(get_build_stats)

    local LOG_LINK=""
    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        if command -v gzip &> /dev/null; then gzip -9 "$LOG_FILE"; LOG_FILE="${LOG_FILE}.gz"; fi
        local GO_RESP=$(gofile_upload "$LOG_FILE")
        if [ -n "$GO_RESP" ]; then
            LOG_LINK=$(echo "$GO_RESP" | jq -r '.data.downloadPage' 2>/dev/null || true)
        else
            LOG_LINK=$(pixeldrain_upload "$LOG_FILE" || true)
        fi
    fi

    local END_TIME=$(date +%s)
    local ELAPSED_MINUTES=$(((END_TIME - START_TIME) / 60))
    local FAIL_MSG="❌ <b>BUILD FAILED</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Time:</b> ${ELAPSED_MINUTES}m%0A- <b>Error:</b> Line ${FAILED_LINE}"
    if [ -n "$BUILD_STATS" ]; then FAIL_MSG="${FAIL_MSG}%0A- <b>Build Stats:</b> ${BUILD_STATS} actions"; fi
    if [ -n "$LOG_LINK" ]; then FAIL_MSG="${FAIL_MSG}%0A- 📄 <a href=\"${LOG_LINK}\" >View Crash Log</a>"; fi
    edit_tg_msg "$START_MSG_ID" "$FAIL_MSG"
    exit 1
}

trap 'handle_error $LINENO' ERR

START_MSG="🔄 <b>BUILD STARTED</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Host:</b> $(hostname)"
START_MSG_ID=$(send_tg_msg_with_button "$START_MSG")

# =============================
#  MistOS Build Script
#  For: Vanilla & GAPPS
# =============================

# --- Remove old local manifests ---
rm -rf .repo/local_manifests
rm -rf .repo/manifests
rm -rf .repo/manifest.xml

# --- Remove Device Settings --- (Reason: It Will fail sync when we re run this script)
rm -rf packages/resources/devicesettings

# --- Init ROM repo ---
repo init --depth=1 -u https://github.com/Project-Mist-OS/manifest -b bp2a --git-lfs && \

# --- Sync ROM ---
/opt/crave/resync.sh && \
#repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all) && \

# --- Clone Device Tree ---
rm -rf device/xiaomi
git clone https://github.com/MurtazaKolachi/device_xiaomi_apollo -b mist device/xiaomi/apollo && \

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

# Remove output directories to be on safer side
rm -rf out/target/product/vanilla &&
rm -rf out/target/product/gapps &&

# =============================
#       Build: Vanilla
# =============================

# --- Vanilla Build ---
echo "===== Starting Vanilla Build ====="
touch "/tmp/build_active_apollo"
start_build_tracker "$START_MSG_ID" "$ROM_NAME" "$DEVICE" "Vanilla Build"

set +e
. build/envsetup.sh && \
mistify apollo user && \
make installclean && \
mist b
BUILD_EXIT_CODE=$?
set -e

rm -f "/tmp/build_active_apollo"
kill "$TRACKER_PID" 2>/dev/null || true

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    exit $BUILD_EXIT_CODE
fi

echo "===== Handling Vanilla Output ====="
mv out/target/product/apollo out/target/product/vanilla && \

# --- Gapps Build ---
echo "===== Setting up for Gapps Build ====="
touch "/tmp/build_active_apollo"
start_build_tracker "$START_MSG_ID" "$ROM_NAME" "$DEVICE" "Gapps Build"

set +e
make installclean && \
mist b
BUILD_EXIT_CODE=$?
set -e

rm -f "/tmp/build_active_apollo"
kill "$TRACKER_PID" 2>/dev/null || true

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    exit $BUILD_EXIT_CODE
fi

echo "===== Handling Gapps Output ====="
mv out/target/product/apollo out/target/product/gapps && \

echo "===== All builds completed successfully! ====="

if grep -q -E "ninja failed|failed to build some targets" "$LOG_FILE" 2>/dev/null; then
    echo "❌ Ninja build failure detected in log!"
    handle_error $LINENO
fi

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
    MASTER_LINK=""
        GUEST_TOKEN=""
        FOLDER_ID=""
        UPLOAD_FAILED=0

        for FILE_PATH in "${FILES_TO_UPLOAD[@]}"; do
            echo "📤 Uploading $(basename "$FILE_PATH")..."
            
            UPLOAD_MSG="📤 <b>UPLOADING ARTIFACTS</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>File:</b> $(basename "$FILE_PATH")"
            edit_tg_msg_with_button "$START_MSG_ID" "$UPLOAD_MSG"

            UPLOAD_RES=$(gofile_upload "$FILE_PATH" "$GUEST_TOKEN" "$FOLDER_ID")

            if [ -n "$UPLOAD_RES" ]; then
                echo "✅ Successfully uploaded $(basename "$FILE_PATH") to GoFile"
                if [ -z "$GUEST_TOKEN" ]; then
                    MASTER_LINK=$(echo "$UPLOAD_RES" | jq -r '.data.downloadPage' 2>/dev/null || true)
                    GUEST_TOKEN=$(echo "$UPLOAD_RES" | jq -r '.data.guestToken' 2>/dev/null || true)
                    FOLDER_ID=$(echo "$UPLOAD_RES" | jq -r '.data.parentFolder' 2>/dev/null || true)
                fi
            else
                echo "⚠️ GoFile upload failed for $(basename "$FILE_PATH"), trying PixelDrain..."
                PD_LINK=$(pixeldrain_upload "$FILE_PATH")
                if [ -n "$PD_LINK" ]; then
                    echo "✅ Successfully uploaded $(basename "$FILE_PATH") to PixelDrain: $PD_LINK"
                    if [ -z "$MASTER_LINK" ]; then MASTER_LINK="$PD_LINK"; fi
                else
                    echo "❌ Failed to upload $(basename "$FILE_PATH") to both hosts."
                    if [[ "$FILE_PATH" == *.zip ]]; then UPLOAD_FAILED=1; fi
                fi
            fi
        done

        if [ "$UPLOAD_FAILED" -eq 0 ] && [ -n "$MASTER_LINK" ]; then
            END_TIME=$(date +%s)
            ELAPSED_MINUTES=$(((END_TIME - START_TIME) / 60))
            SUCCESS_MSG="🚀 <b>BUILD SUCCESSFUL</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Time:</b> ${ELAPSED_MINUTES}m"
            if [ -n "$BUILD_STATS" ]; then SUCCESS_MSG="${SUCCESS_MSG}%0A- <b>Build Stats:</b> ${BUILD_STATS} actions"; fi
            SUCCESS_MSG="${SUCCESS_MSG}%0A- 🔗 <a href=\"${MASTER_LINK}\" >Download Artifacts</a>"
            edit_tg_msg "$START_MSG_ID" "$SUCCESS_MSG"
        else
            echo "❌ ROM upload failed."
            END_TIME=$(date +%s)
            ELAPSED_MINUTES=$(((END_TIME - START_TIME) / 60))
            FAIL_MSG="❌ <b>UPLOAD FAILED</b>%0A- <b>Device:</b> ${DEVICE}%0A- <b>ROM:</b> ${ROM_NAME}%0A- <b>Time:</b> ${ELAPSED_MINUTES}m%0A- <b>Error:</b> ROM zip upload failed"
            edit_tg_msg "$START_MSG_ID" "$FAIL_MSG"
        fi
fi

exec 1>&3 2>&4
sleep 1
if [ -f "$LOG_FILE" ] && command -v gzip &> /dev/null; then gzip -9 "$LOG_FILE"; fi
