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

# Why the GLES driver is NOT switched to ANGLE.
#
# ANGLE (the libEGL_angle / libGLESv1_CM_angle / libGLESv2_angle drivers already
# shipped by generic.mk) implements OpenGL ES on top of Vulkan: GLES calls are
# translated to Vulkan in-guest and only Vulkan crosses to the host via the
# gfxstream VkDecoder. It exposes full GLES 3.2 and better multisample behaviour
# without patching gfxstream's GLES path, so it looks like a straight upgrade.
#
# Selecting it is a one-line change: Android's EGL loader picks the driver by the
# ro.hardware.egl suffix (libEGL_<suffix>.so), and setting ro.hardware.egl=angle
# here would land it in build.prop, which second-stage init loads before
# `on early-init` runs -- ro.* properties are write-once, so it would win over
# init.ranchu.rc's later setprop. Do not make that change without re-measuring:
#
# BOTH PROPERTIES ARE LEFT OFF DELIBERATELY. ANGLE boots and runs on this image
# once virtio-gpu supplies Vulkan (see advancedFeatures.ini.digitalis above), but
# measuring it against gfxstream's GLES on the prebuilt game corpus shows it is a
# net loss, so the default stays on gfxstream.
#
# Measured on one pristine boot each (8 apps installed, no memory pressure), the
# same games, three launch attempts apiece:
#
#   ANGLE fixes    beachbuggy (0/60 -> renders), dr2play (0/60 -> 22/60)
#   ANGLE breaks   artblitz, bouncyhoops, bucketcrusher, burgerplease
#                  (all pass under gfxstream GLES; all 0/60 under ANGLE, 3/3)
#   ANGLE weakens  ballz 60/60 -> 14/60, bowmasters -> 8/60
#
# Four regressions to buy two fixes is not a trade worth taking, and the two
# games it fixes render blank under gfxstream for reasons that belong in
# gfxstream's GLES path rather than in a driver swap for the whole image.
#
# If this is revisited, note that ANGLE also needs the gfxstream process-teardown
# fix in the host (digitalis/docs/emulator-gfxstream-deploy.md, Symptom 4): ANGLE
# routes every app through the Vulkan decoder, which turns a rare host race into a
# SIGSEGV about a minute into every boot.
#
# ro.hardware.egl is therefore left to init.ranchu.rc, which derives it from
# ${ro.boot.hardwareegl:-emulation} and so selects gfxstream's GLES driver, and
# ro.opengles.version is left to the emulator's ro.boot.opengles.version (3.1).
# Advertising 3.2 here would overstate what gfxstream's GLES provides.
# init.ranchu.rc's ANGLE feature override is a no-op unless ANGLE is the driver.

# Overrides
PRODUCT_BRAND := Android
PRODUCT_NAME := sdk_phone64_x86_64_digitalis
PRODUCT_DEVICE := emu64xa
PRODUCT_MODEL := Android SDK built for x86_64 with ARM64 translated (Digitalis)
