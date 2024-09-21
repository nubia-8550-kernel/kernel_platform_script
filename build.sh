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
  vendor/qcom/opensource/wlan/platform
  vendor/qcom/opensource/wlan/qcacld-3.0/.kiwi_v2
  vendor/qcom/opensource/bt-kernel
"

export LTO=thin

RECOMPILE_KERNEL=1 ./kernel_platform/build/android/prepare_vendor.sh ${TARGET_BOARD_PLATFORM} gki

KERNEL_BUILD_ROOT=`pwd`

sed 's+scripts/unifdef+$LOC_UNIFDEF+g' kernel_platform/msm-kernel/scripts/headers_install.sh > out/headers_install.sh

UNIFDEF=$KERNEL_BUILD_ROOT/out/msm-kernel-kalama/msm-kernel/scripts/unifdef
HEADERS_INSTALL=$KERNEL_BUILD_ROOT/out/headers_install.sh
KERNEL_HEADERS_GEN_DIR=$KERNEL_BUILD_ROOT/device/qcom/kalama-kernel/kernel-headers

mkdir -p $KERNEL_HEADERS_GEN_DIR

HEADERS_GEN_SCRIPTS=(
  'vendor/qcom/opensource/audio-kernel audio_kernel_headers.py --audio_include_uapi include/uapi/audio/'
  'vendor/qcom/opensource/display-drivers display_kernel_headers.py --display_include_uapi include/uapi/'
  'vendor/qcom/opensource/graphics-kernel gfx_kernel_headers.py --gfx_include_uapi include/uapi/linux/'
  'vendor/qcom/opensource/mm-drivers mm_drivers_kernel_headers.py --mm_drivers_include_uapi sync_fence/include/uapi/'
  'vendor/qcom/opensource/video-driver video_kernel_headers.py --video_include_uapi include/uapi/'
)

for script in "${HEADERS_GEN_SCRIPTS[@]}"; do
    set -- $script
    cd $KERNEL_BUILD_ROOT/$1

    headers=`find ./$4 -type f -name '*.h' | paste -sd ' '`

    for hdr in $headers; do
        mkdir -p $KERNEL_HEADERS_GEN_DIR/`dirname \`realpath --relative-to=./$4 $hdr\``
    done

    python3 $2 \
            --verbose \
            --header_arch arm64 \
            --gen_dir $KERNEL_HEADERS_GEN_DIR \
            --unifdef $UNIFDEF \
            --headers_install $HEADERS_INSTALL \
            $3 $headers
    cd $KERNEL_BUILD_ROOT
done

REMOVE_HEADERS="
  linux/udp.h
"

for header in $REMOVE_HEADERS; do
    rm $KERNEL_HEADERS_GEN_DIR/$header
done
