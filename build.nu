#!/usr/bin/env nu

# Build all ZMK firmware targets and collect UF2 files in output/.
#
# Usage:
#   nu build.nu              # build everything
#   nu build.nu buttercorne  # build one target by name
#
# Requires arm-none-eabi-gcc:  sudo pacman -S arm-none-eabi-gcc
# Requires west in venv:       uv tool install west  (or ~/zmk-dev/.venv)

def main [
    ...targets: string  # optional: buttercorne, corne_left, corne_right (default: all)
] {
    let project_dir = $env.PWD

    # Add venv to PATH so `west` is found
    $env.PATH = ($env.PATH | prepend $"($env.HOME)/zmk-dev/.venv/bin")
    $env.ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb"
    $env.GNUARMEMB_TOOLCHAIN_PATH = "/usr"

    let all_builds = [
        {
            name: "buttercorne"
            board: "buttercorne"
            dir: "build/buttercorne"
            cmake: [$"-DZMK_CONFIG=($project_dir)/config" $"-DBOARD_ROOT=($project_dir)"]
        }
        {
            name: "corne_left"
            board: "nice_nano//zmk"
            dir: "build/left"
            cmake: [$"-DZMK_CONFIG=($project_dir)/config" "-DSHIELD=corne_left"]
        }
        {
            name: "corne_right"
            board: "nice_nano//zmk"
            dir: "build/right"
            cmake: [$"-DZMK_CONFIG=($project_dir)/config" "-DSHIELD=corne_right"]
        }
    ]

    let builds = if ($targets | is-empty) {
        $all_builds
    } else {
        $all_builds | where { |b| $b.name in $targets }
    }

    if ($builds | is-empty) {
        error make { msg: $"Unknown target(s): ($targets | str join ', '). Valid: buttercorne, corne_left, corne_right" }
    }

    mkdir output

    for build in $builds {
        print $"\n== Building ($build.name) =="
        ^west build -p -b $build.board --build-dir $build.dir zmk/app -- ...$build.cmake
        let uf2 = $"($build.dir)/zephyr/zmk.uf2"
        let dest = $"output/($build.name).uf2"
        cp $uf2 $dest
        print $"   -> ($dest)"
    }

    print "\nDone."
    ls output/*.uf2
}
