# SPDX-License-Identifier: MIT
# Suppress known duplicate unit-address warnings from nRF52840 SoC DTS
list(APPEND EXTRA_DTC_FLAGS "-Wno-unique_unit_address_if_enabled")
