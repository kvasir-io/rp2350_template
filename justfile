# Build, flash and log helpers for the RP2350 template.
#
#   just                 # this list, with examples
#   just build           # the default variant
#   just build-all       # all four, warning-free
#   just flash release_log && just log release_log
#
# Four variants come out of kvasir_executable_variants: debug, release,
# release_log and sanitize, each with a flash_<v> target and, but release, a log_<v>.
#
# Dependency checkouts are resolved as siblings of this repository and can be
# pointed anywhere:  `just chip_root=/path/to/chip_rp2350 build`, or via
# $KVASIR_ROOT / $CHIP_ROOT / $KVASIR_DEVICES_ROOT.
# If the siblings are not there, no path is passed to CMake at all and
# CMakeLists.txt clones all three with FetchContent into build/_deps; the
# justfile's own tools (fw.py, tidy.py) then come from a shallow SDK clone in
# .kvasir_sdk/ (see kvasir_root below).
#
# `just` itself: `sudo pacman -S just` (or `cargo install just`).

set shell := ["bash", "-euo", "pipefail", "-c"]
# Assignments are evaluated when a recipe uses them: the compiler/library mapping (fw.py config) starts python only
# for a recipe that needs a tree, never for a root recipe that merely loads this module.
set lazy := true

root := source_directory()
self := source_file()   # not justfile(): that names the ROOT justfile when loaded as a module
tree := parent_directory(root)
# The ARM compiler: clang (the default) or gcc. `just compiler=gcc build-all` here, or KVASIR_COMPILER=gcc in the
# environment (the work tree's `just compiler=gcc build` sets it for every module). A gcc build has trees of its
# own - the clang tree's name with _gcc - so both stay configured side by side.
compiler := env('KVASIR_COMPILER', 'clang')
# The C and C++ libraries: llvm (libc++ + llvm-libc, clang's default) or newlib (libstdc++ + newlib, gcc's default).
# `just libs=newlib build-all` here, or KVASIR_LIBS in the environment (the work tree's `just libs=newlib build`).
# The compiler's own default keeps the tree name above; the other one adds _newlib (clang) or _llvm (gcc): build,
# build_newlib, build_gcc, build_gcc_llvm.
libs := env('KVASIR_LIBS', if compiler == "gcc" { "newlib" } else { "llvm" })
compiler_suffix := shell('python3 -B "$1" config --compiler "$2" --libs "$3" suffix', fw, compiler, libs)
compiler_flag := shell('python3 -B "$1" config --compiler "$2" --libs "$3" cmake-flags', fw, compiler, libs)
build_dir := root / "build" + compiler_suffix
# No -j on the cmake --build lines: ninja picks its own parallelism (cpus + 2)
# and, under the work tree's `just build`, draws from GNU make's shared job
# pool instead - an explicit -j would opt it out of that pool.

# Kvasir_SDK: $KVASIR_ROOT, else the sibling checkout, else a shallow clone of master (no submodules) in .kvasir_sdk/ -
# only for its tools (fw.py, tidy.py), which every recipe needs before CMake runs; CMake fetches its own copy into
# build/_deps. `just clean-all` removes the clone, the next recipe clones master again.
sibling_sdk := tree / "Kvasir_SDK"
kvasir_root := env('KVASIR_ROOT', if path_exists(sibling_sdk / "tools" / "fw.py") == "true" { sibling_sdk } else { root / ".kvasir_sdk" })
# The shared guard and build-all filter (Kvasir_SDK/tools/fw.py), from the SDK this tree builds with
fw := shell('[ -f "$1/tools/fw.py" ] || [ "$1" != "$2" ] || git clone --quiet --depth 1 https://github.com/kvasir-io/Kvasir_SDK.git "$1" >&2; echo "$1/tools/fw.py"', kvasir_root, root / ".kvasir_sdk")
chip_root := env('CHIP_ROOT', tree / 'chip_rp2350')
devices_root := env('KVASIR_DEVICES_ROOT', tree / 'kvasir_devices')

# Which J-Link on USB: a serial number or a nickname. Empty takes the only one
# connected; with two on the bus JLinkExe cannot connect and the printer refuses
# to start, so name it here or with $JLINK_PROBE.
probe := env('JLINK_PROBE', '')

variants := "debug release release_log sanitize"
default_variant := "release_log"

# This list, with examples. `just` on its own.
default:
    @just --list --unsorted
    @echo ""
    @echo "EXAMPLES"
    @echo "  just build                       {{ default_variant }}, incremental"
    @echo "  just build debug                 one variant"
    @echo "  just build-all                   all four, warning-free"
    @echo "  just flash release_log           build it, then write it to the board"
    @echo "  just log release_log             uc_log_printer on that image"
    @echo "  just probe='<nickname or serial>' flash release_log"
    @echo ""
    @echo "VARIANTS  {{ variants }}"
    @echo "PATHS     KVASIR_ROOT  {{ kvasir_root }}"
    @echo "          CHIP_ROOT    {{ chip_root }}"
    @echo "          DEVICES_ROOT {{ devices_root }}"

# Wipe a build tree the checkout outgrew: a moved source directory, a recorded dependency checkout (any *_ROOT in
# the cache) that no longer exists, a tree configured with another generator (every recipe here drives Ninja), or a
# configure that never finished (an interrupted one leaves a CMakeCache.txt without CMAKE_PROJECT_NAME). Without
# this CMake refuses outright: "the current CMakeCache.txt directory ... is different than the directory".
# Kvasir_SDK/tools/fw.py guard.
[private]
guard:
    @python3 -B "{{ fw }}" guard --tree "{{ build_dir }}" --source "{{ root }}"

# Configure build/ if it is not configured yet (no-op afterwards)
configure: guard
    #!/usr/bin/env bash
    set -euo pipefail
    # build.ninja, not CMakeCache.txt: an interrupted configure leaves a cache and no build files.
    if [ -f "{{ build_dir }}/build.ninja" ]; then exit 0; fi
    # All three roots or none: a half-filled set would mix a sibling SDK with
    # freshly cloned masters of the other two; the tools clone in .kvasir_sdk/
    # has no submodules and never goes to CMake.
    roots=()
    if [ "{{ kvasir_root }}" != "{{ root }}/.kvasir_sdk" ] && [ -d "{{ chip_root }}" ] && [ -d "{{ devices_root }}" ]; then
        roots=(-DKVASIR_ROOT="{{ kvasir_root }}"
               -DCHIP_ROOT="{{ chip_root }}"
               -DKVASIR_DEVICES_ROOT="{{ devices_root }}")
    else
        echo "==> no sibling checkouts; FetchContent will clone into {{ build_dir }}/_deps"
    fi
    # CC/CXX are for the NATIVE sub-builds (uc_log_printer, svd_converter);
    # the ARM toolchain file is chosen by the SDK from COMPILE_TARGET.
    env CC=clang CXX=clang++ cmake -S "{{ root }}" -B "{{ build_dir }}" -G Ninja \
        {{ compiler_flag }} \
        "${roots[@]}" \
        -DUSE_FORCE_FETCH=ON \
        {{ if probe == "" { "" } else { "-DJLINK_PROBE='" + probe + "'" } }}

# Wipe build/ and configure it again
reconfigure: clean configure

# Build one variant (incremental)
build variant=default_variant: configure
    cmake --build "{{ build_dir }}" --target {{ variant }}

# Build all four variants. Silence is the pass condition - a warning is a failure.
build-all: configure
    @python3 -B "{{ fw }}" build-all --tree "{{ build_dir }}" --ok "all four variants built warning-free" -- {{ variants }}

# Build a variant and write it to the board over J-Link
flash variant=default_variant: configure
    cmake --build "{{ build_dir }}" --target flash_{{ variant }}

# Run uc_log_printer against a variant's log
log variant=default_variant: configure
    cmake --build "{{ build_dir }}" --target log_{{ variant }}

# Reset the board through the probe
reset: configure
    cmake --build "{{ build_dir }}" --target reset

# Attach to the board through the probe without resetting it
connect: configure
    cmake --build "{{ build_dir }}" --target connect

# Every target CMake generates, for when a name is not obvious
targets: configure
    @cmake --build "{{ build_dir }}" --target help | sed 's/^\.\.\. //' | sort

# Remove build/
clean:
    rm -rf "{{ build_dir }}"

# Remove build/, the container-side docker_build/ and the cloned SDK tools (.kvasir_sdk/)
clean-all:
    rm -rf "{{ build_dir }}" "{{ root }}/docker_build" "{{ root }}/.kvasir_sdk"

# --- clang-tidy ----------------------------------------------------------------

# Kvasir_SDK/tools/tidy.py with the SDK's .clang-tidy: findings in this repository fail, the libraries' count as
# foreign. `just tidy --changed`, `just tidy --fix`, `--audit <check>`, `--only '<glob>'`. A gcc tree (compiler=gcc)
# is refused: clang-tidy reads clang command lines only.
# clang-tidy over this firmware's clang tree (exit 0 clean, 1 findings)
[positional-arguments]
tidy *args: configure
    python3 -B "{{ kvasir_root }}/tools/tidy.py" --tree "{{ build_dir }}" --repo "{{ root }}" \
        {{ if path_exists(tree / "tools" / "tidy_keep_workspace.toml") == "true" { "--overlay '" + tree / "tools" / "tidy_keep_workspace.toml" + "'" } else { "" } }} "$@"

# The configured clang tree `tidy` reads, if there is one (the workspace's `just tidy` collects them)
tidy-trees:
    #!/usr/bin/env bash
    set -euo pipefail
    d=$(KVASIR_COMPILER=clang KVASIR_LIBS=llvm just --justfile "{{ source_file() }}" --evaluate build_dir)
    [ ! -f "$d/compile_commands.json" ] || echo "$d"
