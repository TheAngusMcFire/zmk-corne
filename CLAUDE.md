# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a ZMK firmware configuration repository for a Corne split keyboard using nice!nano v2 controllers. Firmware is built via GitHub Actions — there is no local build toolchain in this repo.

## Building Firmware

### GitHub Actions (default)

Firmware builds automatically on every push/PR (`.github/workflows/build.yml`). The build matrix in `build.yaml` produces three firmware files:
- `corne_left` — left half (nice_nano_v2)
- `corne_right` — right half (nice_nano_v2)
- `settings_reset` — clears stored settings when flashed

ZMK pulls from its `main` branch as defined in `config/west.yml`.

### Local builds

**One-time setup** (run from the repo root):

```bash
# Install west
uv tool install west

# Fetch ZMK + Zephyr (downloads ~500 MB, takes a few minutes)
west update

# Export Zephyr CMake package
west zephyr-export

# Install Python deps into a venv
python3 -m venv ~/zmk-dev/.venv
~/zmk-dev/.venv/bin/pip install west -q
~/zmk-dev/.venv/bin/pip install -r zephyr/scripts/requirements-base.txt -q
```

**Build commands** (requires `arm-none-eabi-gcc` — install via `pacman -S arm-none-eabi-gcc`):

```bash
source ~/zmk-dev/.venv/bin/activate

# Left half
ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb GNUARMEMB_TOOLCHAIN_PATH=/usr \
  west build -p -b 'nice_nano//zmk' --build-dir build/left zmk/app -- \
    -DSHIELD=corne_left \
    -DZMK_CONFIG="$(pwd)/config"

# Right half
ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb GNUARMEMB_TOOLCHAIN_PATH=/usr \
  west build -p -b 'nice_nano//zmk' --build-dir build/right zmk/app -- \
    -DSHIELD=corne_right \
    -DZMK_CONFIG="$(pwd)/config"
```

Output `.uf2` files land at `build/left/zephyr/zmk.uf2` and `build/right/zephyr/zmk.uf2`.

Notes:
- Since Zephyr 4.1, the board name requires the `//zmk` variant qualifier (`nice_nano//zmk`). The `//` skips SoC/cpucluster levels to address the variant directly.
- `-p` (pristine) is required when switching between left/right shields.
- Omit `-p` for incremental rebuilds after keymap-only edits.

**Buttercorne (standalone custom nRF52840 board):**

```bash
source ~/zmk-dev/.venv/bin/activate

ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb GNUARMEMB_TOOLCHAIN_PATH=/usr \
  west build -p -b buttercorne --build-dir build/buttercorne zmk/app -- \
    -DZMK_CONFIG="$(pwd)/config" \
    -DBOARD_ROOT="$(pwd)"
```

Output: `build/buttercorne/zephyr/zmk.uf2` (~370 KB with BLE+USB)

Note: `-DBOARD_ROOT=$(pwd)` is required so Zephyr finds the board definition at `boards/custom/buttercorne/`. This isn't needed for corne because nice_nano is discovered through ZMK's own module.

## Repository Structure

```
config/
  corne.keymap          # Keymap for Corne (42 keys: 6 cols/side × 3 rows + 3 thumbs/side)
  corne.conf            # Feature flags for Corne (RGB, OLED — disabled)
  buttercorne.keymap    # Keymap for Buttercorne (36 keys: 5 cols/side × 3 rows + 3 thumbs/side)
  buttercorne.conf      # Feature flags for Buttercorne (BLE + USB enabled)
  west.yml              # ZMK dependency manifest
boards/custom/buttercorne/
  board.yml             # Zephyr board metadata (vendor: custom, soc: nrf52840)
  buttercorne.dts       # Hardware DTS: GPIO matrix, flash partitions, USB
  buttercorne_defconfig # Kconfig base config
  Kconfig.buttercorne   # Selects SOC_NRF52840_QIAA for this board
  pre_dt_board.cmake    # Suppresses benign DTS warnings
build.yaml              # GitHub Actions build matrix
zephyr/module.yml       # Registers repo as a Zephyr module (board_root: .)
```

## Keymap Architecture (`config/corne.keymap`)

### Custom Behaviors

- **`ht`** — tap-preferred hold-tap, 150ms tapping term (used for home row mods)
- **`hta`** — tap-preferred hold-tap, 240ms (Alt/Mod variants)
- **`hts`** — hold-preferred hold-tap, 400ms (Shift keys)
- **`td0`** — tap-dance: Y on single tap, ESC on double-tap

### Layer Structure

| Layer | Name | Access |
|-------|------|--------|
| 0 | Default (QWERTY) | Always active |
| 1 | Numbers/Navigation | Hold Backspace |
| 2 | Symbols | Hold Tab |
| 3 | Functions/Bluetooth | Conditional: layers 1 AND 2 held (tri-layer) |
| 4 | Gaming | Toggle key on layer 1 |

### Layer 0 — Default

Home row modifiers on both halves (Shift/Alt/Ctrl/GUI on left, mirrored on right). The outermost thumb keys are dedicated Shift keys (`hts`). Tab (hold → layer 2) and Backspace (hold → layer 1) serve as the primary layer activators.

### Layer 1 — Numbers/Navigation

Numbers row (1–0), arrow keys and page navigation on right side. Includes CAPS_WORD and a toggle to layer 4 (gaming).

### Layer 2 — Symbols

Symbol equivalents of the number row (`!@#$%` / `^&*()`), plus programming symbols (`-=[]\`, `_+{}|`, quotes, backtick, tilde).

### Layer 3 — Functions/Bluetooth (Tri-layer)

F1–F12, Bluetooth device selection (5 slots via `BT_SEL`), Bluetooth clear, and reset/bootloader access on both halves.

### Layer 4 — Gaming

WASD layout with Tab, LShift, LCtrl. Right side is fully transparent (disabled).

## Enabling Optional Features

To enable features, uncomment the relevant lines in `config/corne.conf`:
- RGB underglow: `CONFIG_ZMK_RGB_UNDERGLOW=y`
- WS2812 strip: `CONFIG_WS2812_STRIP=y`
- OLED display: `CONFIG_ZMK_DISPLAY=y`
