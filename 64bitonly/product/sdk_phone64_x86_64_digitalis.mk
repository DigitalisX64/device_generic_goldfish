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
# (25G vs the inherited 10G) so prebuilt ARM64 APKs — which are large and
# expand on install — fit without passing -partition-size at launch. This must
# precede the inherit below: PRODUCT_COPY_FILES dedups by destination keeping
# the first entry, so this wins over phone.mk's config.ini.nexus5.
PRODUCT_COPY_FILES += \
    device/generic/goldfish/data/etc/config.ini.digitalis:config.ini

$(call inherit-product, device/generic/goldfish/64bitonly/product/sdk_phone64_x86_64.mk)

$(call inherit-product, frameworks/libs/binary_translation/enable_arm64_to_x86_64.mk)

# Overrides
PRODUCT_BRAND := Android
PRODUCT_NAME := sdk_phone64_x86_64_digitalis
PRODUCT_DEVICE := emu64xa
PRODUCT_MODEL := Android SDK built for x86_64 with ARM64 translated (Digitalis)
