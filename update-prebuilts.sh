#!/bin/bash
#
# SPDX-FileCopyrightText: Paranoid Android
# SPDX-License-Identifier: Apache-2.0
#
# Collect kernel prebuilts for AOSPA (KERNEL_PREBUILT_DIR) from a built tree.
#
# Expected inputs (override via env):
#   ANDROID_TOP   top of the Android tree holding out/ and the kernel repos
#   OUT_PRODUCT   $ANDROID_TOP/out/target/product/onyx
#   KERNEL_OUT    soong intermediates of the kernel module
#   KERNEL_SRC    kernel/xiaomi/sm8735
#   KERNEL_MODS   kernel/xiaomi/sm8735-modules
#   MODULE_LISTS  device/xiaomi/onyx/modules

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ANDROID_TOP="${ANDROID_TOP:-$(cd "$REPO_DIR/../../.." && pwd)}"
OUT_PRODUCT="${OUT_PRODUCT:-$ANDROID_TOP/out/target/product/onyx}"
KERNEL_OUT="${KERNEL_OUT:-$ANDROID_TOP/out/soong/.intermediates/device/xiaomi/onyx/kernel/android_arm64_armv8-2a-dotprod}"
KERNEL_SRC="${KERNEL_SRC:-$ANDROID_TOP/kernel/xiaomi/sm8735}"
KERNEL_MODS="${KERNEL_MODS:-$ANDROID_TOP/kernel/xiaomi/sm8735-modules}"
MODULE_LISTS="${MODULE_LISTS:-$ANDROID_TOP/device/xiaomi/onyx/modules}"

echo "==> ANDROID_TOP=$ANDROID_TOP"

# --- Kernel image and device trees -----------------------------------------
install -D "$KERNEL_OUT/kernel/Image" "$REPO_DIR/Image"
install -D "$OUT_PRODUCT/dtb.img" "$REPO_DIR/dtbs/dtb.img"
install -D "$OUT_PRODUCT/dtbo.img" "$REPO_DIR/dtbs/dtbo.img"

# --- Kernel modules by partition -------------------------------------------
FLAT="$KERNEL_OUT/modules_flat"
rm -rf "$REPO_DIR/vendor_ramdisk" "$REPO_DIR/vendor_dlkm" "$REPO_DIR/system_dlkm"
mkdir -p "$REPO_DIR/vendor_ramdisk" "$REPO_DIR/vendor_dlkm" "$REPO_DIR/system_dlkm"

collect() {
    local dest="$1" list
    shift
    for list in "$@"; do
        [ -f "$list" ] || { echo "!! missing list $list"; continue; }
        while read -r mod; do
            mod="${mod%%#*}"
            mod="$(echo "$mod" | tr -d '[:space:]')"
            [ -z "$mod" ] && continue
            if [ -f "$FLAT/$mod" ]; then
                cp "$FLAT/$mod" "$dest/"
            else
                echo "!! $mod not built (wanted in $(basename "$dest"))"
            fi
        done < <(grep -v '^#' "$list" | grep -v '^$')
    done
}

collect "$REPO_DIR/vendor_ramdisk" \
    "$MODULE_LISTS/modules.list.msm.sun" \
    "$MODULE_LISTS/modules.list.first_stage" \
    "$MODULE_LISTS/modules.list.second_stage"
collect "$REPO_DIR/vendor_dlkm" \
    "$MODULE_LISTS/modules.list.second_stage" \
    "$MODULE_LISTS/modules.list.vendor_dlkm"
collect "$REPO_DIR/system_dlkm" \
    "$MODULE_LISTS/modules.include.system_dlkm"

# --- Kernel headers for HALs (qti_kernel_headers contract) ------------------
# Same layout as AOSPA's marble-kernel: headers are looked up by file name in
# the kernel module sources and staged under their contract path.
missing=0
while read -r rel; do
    case "$rel" in
        kernel-headers/*.*) ;;
        *) continue ;;
    esac
    base="$(basename "$rel")"
    src="$(find "$KERNEL_MODS" "$KERNEL_SRC" -type f -name "$base" \
            -not -path "*/out/*" -not -path "*/bazel-*" 2>/dev/null | head -1)"
    if [ -n "$src" ]; then
        install -D "$src" "$REPO_DIR/$rel"
    else
        echo "!! header not found: $base"
        missing=$((missing + 1))
    fi
done < "$REPO_DIR/kernel-headers.list"

echo "==> done (missing headers: $missing)"
