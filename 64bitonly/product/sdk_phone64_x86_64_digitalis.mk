#
# Copyright (C) 2026 utzcoz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# sdk_phone64_x86_64 with ARM64 translated (Digitalis)

# Ship a Digitalis-specific emulator config.ini with a larger data partition
# (80G vs the inherited 10G) so prebuilt ARM64 APKs — which are large and expand
# on install, plus asset-heavy games like Genshin Impact (~60-80G of post-install
# resource downloads) — fit without passing -partition-size at launch. This must
# precede the inherit below: PRODUCT_COPY_FILES dedups by destination keeping
# the first entry, so this wins over phone.mk's config.ini.nexus5.
PRODUCT_COPY_FILES += \
    device/generic/goldfish/data/etc/config.ini.digitalis:config.ini

$(call inherit-product, device/generic/goldfish/64bitonly/product/sdk_phone64_x86_64.mk)

$(call inherit-product, frameworks/libs/binary_translation/enable_arm64_to_x86_64.mk)

# Default the GLES driver to ANGLE (the libEGL_angle / libGLESv1_CM_angle /
# libGLESv2_angle drivers already shipped by generic.mk) instead of gfxstream's
# GLES emulation. ANGLE implements OpenGL ES on top of Vulkan, so GLES calls are
# translated to Vulkan in-guest and only Vulkan crosses to the host via the
# gfxstream VkDecoder. This gives full GLES 3.2 (which ANGLE exposes) and better
# multisample/MSAA behaviour without patching gfxstream's GLES path.
#
# Android's EGL loader selects the driver by the ro.hardware.egl suffix
# (libEGL_<suffix>.so); for "angle" it loads libEGL_angle.so from /system/lib64.
# init.ranchu.rc sets ro.hardware.egl from ${ro.boot.hardwareegl:-emulation}, so
# it would otherwise default to gfxstream emulation. Setting ro.hardware.egl here
# lands it in build.prop, which second-stage init loads before `on early-init`
# runs; ro.* properties are write-once, so this value wins over init's later
# setprop regardless of whether the emulator supplies androidboot.hardwareegl.
# Scoped to the digitalis product so other goldfish images are unaffected.
#
# DISABLED on AOSP 17 (API 37). ANGLE's Vulkan backend does not initialize
# against the emulator AOSP 17 ships in prebuilts/android-emulator: EGL then
# fails to initialize at all and surfaceflinger aborts in a loop, so the image
# never boots.
#
#   E libEGL : ANGLE Display::initialize error 0: Internal Vulkan error (-3)
#   W libEGL : eglInitialize(...) failed (EGL_NOT_INITIALIZED)
#   F SurfaceFlinger: no suitable EGLConfig found, giving up
#   E init   : process with updatable components 'surfaceflinger' exited 4
#             times before boot completed
#
# That emulator says as much itself on startup: "Guest Angle is still unstable
# for API > 35". The Android 16 tree runs ANGLE because it carries a locally
# rebuilt emulator (prebuilts/android-emulator on branch
# digitalis-local-emulator) with gfxstream fixes that the stock AOSP 17 prebuilt
# does not have. Requiring that build would make a custom emulator a condition
# of running Digitalis 17, so gfxstream's GLES emulation -- the upstream default
# -- stands until the shipped emulator supports ANGLE at this API level.
#
# Re-enable by uncommenting both blocks below; nothing else depends on them.
# init.ranchu.rc's ANGLE feature override stays as it is: it is a no-op unless
# ANGLE is the GLES driver.
#PRODUCT_VENDOR_PROPERTIES += \
#    ro.hardware.egl=angle

# Advertise OpenGL ES 3.2 (0x00030002) to the framework to match the version the
# ANGLE driver now exposes (init.ranchu.rc enables ANGLE's
# exposeNonConformantExtensionsAndVersions). init.ranchu.rc sets ro.opengles.version
# from the emulator's ro.boot.opengles.version (3.1), but ro.* properties are
# write-once and build.prop is loaded first, so this value wins.
# Disabled with the ANGLE default above: without ANGLE the GLES driver is
# gfxstream's, which provides 3.1, so advertising 3.2 here would overstate it.
#PRODUCT_VENDOR_PROPERTIES += \
#    ro.opengles.version=196610

# Overrides
PRODUCT_BRAND := Android
PRODUCT_NAME := sdk_phone64_x86_64_digitalis
PRODUCT_DEVICE := emu64xa
PRODUCT_MODEL := Android SDK built for x86_64 with ARM64 translated (Digitalis)
