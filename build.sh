#!/bin/bash

if [[ -z "${1}" ]]; then
    echo "No platform specified."
    exit
fi
if [[ -z "${2}" ]]; then
    echo "No device specified, building platform only"
    unset TARGET_PRODUCT_NAME
else
    export TARGET_PRODUCT_NAME="${2}"
fi

export TARGET_BOARD_PLATFORM="${1}"
export TARGET_BUILD_VARIANT=user

export ANDROID_BUILD_TOP=$(pwd)
export ANDROID_PRODUCT_OUT=${ANDROID_BUILD_TOP}/out/target/product/${TARGET_BOARD_PLATFORM}
export OUT_DIR=${ANDROID_BUILD_TOP}/out/msm-kernel-${TARGET_BOARD_PLATFORM}

# Create symbolic for external drivers
if [ ! -d "${ANDROID_BUILD_TOP}/kernel_platform/vendor" ]; then
  ln -s "${ANDROID_BUILD_TOP}/vendor" "${ANDROID_BUILD_TOP}/kernel_platform/vendor"
fi

export EXT_MODULES="
  vendor/qcom/opensource/mmrm-driver
  vendor/qcom/opensource/mm-drivers/hw_fence
  vendor/qcom/opensource/mm-drivers/msm_ext_display
  vendor/qcom/opensource/mm-drivers/sync_fence
  vendor/qcom/opensource/audio-kernel
  vendor/qcom/opensource/camera-kernel
  vendor/qcom/opensource/dataipa/drivers/platform/msm
  vendor/qcom/opensource/datarmnet/core
  vendor/qcom/opensource/datarmnet-ext/aps
  vendor/qcom/opensource/datarmnet-ext/offload
  vendor/qcom/opensource/datarmnet-ext/shs
  vendor/qcom/opensource/datarmnet-ext/perf
  vendor/qcom/opensource/datarmnet-ext/perf_tether
  vendor/qcom/opensource/datarmnet-ext/sch
  vendor/qcom/opensource/datarmnet-ext/wlan
  vendor/qcom/opensource/securemsm-kernel
  vendor/qcom/opensource/display-drivers/msm
  vendor/qcom/opensource/eva-kernel
  vendor/qcom/opensource/video-driver
  vendor/qcom/opensource/graphics-kernel
  vendor/qcom/opensource/touch-drivers
  vendor/qcom/opensource/wlan/platform
  vendor/qcom/opensource/wlan/qcacld-3.0/.kiwi_v2
  vendor/qcom/opensource/bt-kernel
  vendor/qcom/opensource/nfc-st-driver
  vendor/qcom/opensource/eSE-driver
  vendor/nxp/opensource/driver
"

export LTO=thin

RECOMPILE_KERNEL=1 ./kernel_platform/build/android/prepare_vendor.sh ${TARGET_BOARD_PLATFORM} gki
