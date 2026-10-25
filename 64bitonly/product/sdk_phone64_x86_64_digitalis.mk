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

# Ship a Digitalis-specific advancedFeatures.ini that turns on the virtio-gpu
# transport. The Android 17 kernel retires the goldfish pipe -- the guest has
# only /dev/goldfish_pipe_dprctd -- and the gfxstream Vulkan driver takes the
# virtio-gpu path instead, so without VirtioGpuNativeSync and
# VirtioGpuFenceContexts there is no /dev/dri/* for it to open: every Vulkan app
# fails vkCreateInstance with VK_ERROR_INITIALIZATION_FAILED and renders a black
# frame, while GLES keeps working through the deprecated pipe node and hides it.
# Same ordering rule as above: this must precede the inherit so it wins over
# phone.mk's advancedFeatures.ini.
PRODUCT_COPY_FILES += \
    device/generic/goldfish/data/etc/advancedFeatures.ini.digitalis:advancedFeatures.ini

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
# This was briefly disabled on AOSP 17 because ANGLE's Vulkan backend could not
# initialize -- EGL failed outright and surfaceflinger aborted in a loop, so the
# image never booted:
#
#   E libEGL : ANGLE Display::initialize error 0: Internal Vulkan error (-3)
#   F SurfaceFlinger: no suitable EGLConfig found, giving up
#
# The cause was not ANGLE. The Android 17 kernel retires the goldfish pipe, so
# the gfxstream Vulkan driver needs the virtio-gpu transport, and without it
# there is no /dev/dri/* and no working Vulkan for ANGLE to build on. With
# virtio-gpu enabled (advancedFeatures.ini.digitalis, plus the matching flags in
# the deployed emulator) ANGLE initializes, surfaceflinger stays up, and the
# image boots.
#
# Keeping ANGLE matters beyond GLES 3.2: on gfxstream's GLES some games render
# nothing at all. Beach Buggy Racing draws a black screen under gfxstream and
# renders normally under ANGLE, matching the Android 16 image almost pixel for
# pixel (1431 vs 1434 distinct colours sampled over the frame).
#
# init.ranchu.rc's ANGLE feature override stays as it is: it is a no-op unless
# ANGLE is the GLES driver.
PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.egl=angle

# Advertise OpenGL ES 3.2 (0x00030002) to the framework to match the version the
# ANGLE driver now exposes (init.ranchu.rc enables ANGLE's
# exposeNonConformantExtensionsAndVersions). init.ranchu.rc sets ro.opengles.version
# from the emulator's ro.boot.opengles.version (3.1), but ro.* properties are
# write-once and build.prop is loaded first, so this value wins.
# Paired with the ANGLE default above; without ANGLE the GLES driver is
# gfxstream's, which provides 3.1, so advertising 3.2 here would overstate it.
PRODUCT_VENDOR_PROPERTIES += \
    ro.opengles.version=196610

# Overrides
PRODUCT_BRAND := Android
PRODUCT_NAME := sdk_phone64_x86_64_digitalis
PRODUCT_DEVICE := emu64xa
PRODUCT_MODEL := Android SDK built for x86_64 with ARM64 translated (Digitalis)
