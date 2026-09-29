# Android device tree: Xiaomi POCO F7 / Redmi Turbo 4 Pro (onyx) kernel prebuilts

Prebuilt kernel artifacts for the POCO F7 / Redmi Turbo 4 Pro (`onyx`),
consumed by AOSPA via `KERNEL_PREBUILT_DIR := device/xiaomi/onyx-kernel`.

Layout (mirrors AOSPA's `android_device_xiaomi_marble-kernel`):

```
Image                 GKI 6.6 kernel image
dtbs/                 dtb.img, dtbo.img
kernel-headers/       UAPI headers for vendor HALs (qti_kernel_headers)
vendor_ramdisk/       first/second stage boot modules
vendor_dlkm/          vendor_dlkm modules
system_dlkm/          GKI (system_dlkm) modules
```

## Updating the prebuilts

Build the kernel as usual (from `kernel/xiaomi/sm8735` +
`kernel/xiaomi/sm8735-modules`, e.g. with the uwuAOSP `uwu_kernel` module),
then run:

```
ANDROID_TOP=/path/to/tree ./update-prebuilts.sh
```

Module partitioning is driven by the lists in `device/xiaomi/onyx/modules/`.
