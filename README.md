# RP2350 Template

A template project for RP2350 development using the Kvasir SDK.

<!-- toc -->

- [Setup Options](#setup-options)
- [Option 1: VSCode Dev Container (Easiest)](#option-1-vscode-dev-container-easiest)
  * [Prerequisites](#prerequisites)
  * [Steps](#steps)
  * [What's Included](#whats-included)
- [Option 2: Docker Development (Manual)](#option-2-docker-development-manual)
  * [Prerequisites](#prerequisites-1)
  * [Steps](#steps-1)
  * [Docker Commands](#docker-commands)
- [Option 3: Native Development (Without Docker)](#option-3-native-development-without-docker)
  * [Prerequisites](#prerequisites-2)
  * [Steps](#steps-2)
- [Build Output](#build-output)
- [Flashing/Debugging with Docker](#flashingdebugging-with-docker)
  * [Prerequisites](#prerequisites-3)
  * [Quick Setup](#quick-setup)
  * [Custom Network Setup](#custom-network-setup)
  * [Notes](#notes)
- [Alternative Flashing Method: Picotool & UF2](#alternative-flashing-method-picotool--uf2)
  * [Using BOOTSEL Mode (No Debug Probe Required)](#using-bootsel-mode-no-debug-probe-required)
  * [Using Picotool (Direct Upload)](#using-picotool-direct-upload)
- [CI/CD](#cicd)
- [Make Targets Reference](#make-targets-reference)
  * [Build Targets](#build-targets)
  * [Flash Targets](#flash-targets)
  * [Log Targets](#log-targets)
- [License](#license)

<!-- tocstop -->

## Setup Options

You can set up this project in three ways: [using VSCode Dev Containers](#option-1-vscode-dev-container-easiest) (easiest), [Docker with manual setup](#option-2-docker-development-manual), or [native development](#option-3-native-development-without-docker).

---

## Option 1: VSCode Dev Container (Easiest)

This is the recommended approach for the fastest and easiest setup. VSCode will automatically configure everything for you.

### Prerequisites

- **VSCode** with the **Dev Containers** extension installed
- **Docker** installed on your system

**Note:** For flashing and debugging, see the [Flashing/Debugging with Docker](#flashingdebugging-with-docker) section below.

### Steps

1. **Open the project in VSCode:**

2. **Reopen in container:**
   - VSCode will detect the dev container configuration
   - Click the "Reopen in Container" button when prompted
   - Or press `F1` → `Dev Containers: Reopen in Container`

3. **Wait for setup** (1-2 minutes on first run):
   - VSCode pulls the Docker image
   - Installs required extensions
   - Configures the build environment

4. **Start developing:**
   - All tools are ready (Clang, CMake, debugger)
   - JLinkRemoteServer is automatically started on your host
   - Build with `Ctrl+Shift+P` → `Tasks: Run Build Task`
   - Flash and debug with `F5`
   - Or use make targets from the terminal (see [Make Targets Reference](#make-targets-reference))

That's it! Everything is pre-configured.

### What's Included

- Clang compiler toolchain
- CMake build system
- VSCode extensions (clangd, cortex-debug)
- Pre-configured build and debug tasks

---

## Option 2: Docker Development (Manual)

This setup uses Docker to provide a pre-configured build environment with all dependencies included.

### Prerequisites

- Docker installed on your system

**Note:** For flashing and debugging, see the [Flashing/Debugging with Docker](#flashingdebugging-with-docker) section below.

### Steps

1. **Start the Docker container:**

   ```bash
   ./scripts/container.sh start
   ```

2. **Attach to the container:**

   ```bash
   ./scripts/container.sh attach
   ```

3. **Build your project from the command line:**

   ```bash
   cd /workspace/project
   ./scripts/build.sh
   ```

   This configures CMake and builds all configurations. After running `build.sh`, you can use make targets for individual operations:

   ```bash
   cd /workspace/project/docker_build

   # Build debug configuration
   make debug

   # Flash debug firmware
   make flash_debug

   # View serial output
   make log_debug
   ```

   See the **Make Targets Reference** section at the end for all available build configurations.

### Docker Commands

```bash
# Start container
./scripts/container.sh start

# Attach to running container (from terminal)
./scripts/container.sh attach

# Stop container
./scripts/container.sh stop
```

**Windows users (PowerShell):** Use `.\scripts\container.ps1` instead:

```powershell
# Start container
.\scripts\container.ps1 start

# Attach to running container
.\scripts\container.ps1 attach

# Stop container
.\scripts\container.ps1 stop
```

---

## Option 3: Native Development (Without Docker)

This setup requires manual installation of dependencies but gives you full control.

### Prerequisites

- **Clang 20+**
- **lld (llvm linker)**
- **CMake 3.28+**
- **Git**
- **python-intelhex**
- [SEGGER J-Link Software](https://www.segger.com/downloads/jlink/)

### Steps

1. **Clone the required Kvasir repositories:**

   ```bash
   # Create a directory for Kvasir dependencies
   mkdir ~/kvasir_deps
   cd ~/kvasir_deps

   # Clone Kvasir SDK (recursively)
   git clone --recursive https://github.com/kvasir-io/Kvasir_SDK

   # Clone chip support (into a folder named "chip")
   git clone --recursive https://github.com/kvasir-io/chip_rp2350 chip

   # Clone device definitions
   git clone --recursive https://github.com/kvasir-io/kvasir_devices
   ```

2. **Configure the project:**

   ```bash
   # Navigate back to your project directory
   cd ~/rp2350_template

   # Create build directory
   mkdir build
   cd build

   # Configure with CMake
   # Replace ~/kvasir_deps/Kvasir_SDK with your actual kvasir_deps location
   env CC=clang CXX=clang++ cmake .. \
     -DKVASIR_ROOT=~/kvasir_deps/Kvasir_SDK \
     -DUSE_FORCE_FETCH=ON
   ```

3. **Build the project:**

   ```bash
   cmake --build . --parallel $(nproc)
   ```

4. **Flash the firmware:**

   ```bash
   make flash_debug
   ```

5. **View serial output (optional):**

   ```bash
   make log_debug
   ```

See the [Make Targets Reference](#make-targets-reference) section for all available build configurations and commands.

---

## Build Output

After building, you'll find the firmware files in the build directory:
- `*.uf2` - Drag-and-drop firmware for RP2350
- `*.elf` - ELF executable with debugging symbols for GDB/debugger
- `*.bin` - Raw binary firmware
- `*.hex` - Intel HEX format firmware
- `*.map` - Memory map showing symbol addresses and section layout
- `*.lst` - Assembly listing with source code
- `*_string_constants.json` - Contains all UC_LOG strings
- `*.ssproj` - Generated [Serial Studio](https://serial-studio.com/) config with plots for all metrics

---

## Flashing/Debugging with Docker

When using Docker (Options 1 or 2), the recommended approach is to use **JLinkRemoteServer**. This is required on Windows because Docker Desktop doesn't expose USB devices to containers.

### Prerequisites

- [SEGGER J-Link Software](https://www.segger.com/downloads/jlink/) installed
- JLinkRemoteServer (included with J-Link Software)
- J-Link probe connected to your RP2350 board

### Quick Setup

**For VSCode Dev Container users (Option 1):**

JLinkRemoteServer is automatically started when you open the dev container. No manual setup required!

**For Docker manual setup users (Option 2):**

1. **Start JLinkRemoteServer on your host machine:**

   **Windows:**
   ```powershell
   JLinkRemoteServer.exe
   ```

   **Linux/Mac:**
   ```bash
   JLinkRemoteServer
   ```

   Leave it running in the background (listens on port 19020 by default).

2. **That's it!** The project is pre-configured to connect to your host machine.

### Custom Network Setup

If you need to use a different IP address (e.g., JLinkRemoteServer on another machine):

**For VSCode users:**

Edit `.devcontainer/devcontainer.json` and change the `JLINK_IP` variable:
```json
"containerEnv": {
  "JLINK_IP": "127.0.0.1"
},
```

**For command-line builds:**
```bash
cmake .. -DJLINK_IP=127.0.0.1
```

Replace `127.0.0.1` with your JLinkRemoteServer's IP address.

### Notes

- **VSCode Dev Container users:** JLinkRemoteServer starts automatically
- **Docker manual setup users:** You must start JLinkRemoteServer manually whenever you want to flash or debug

---

## Alternative Flashing Method: Picotool & UF2

If you don't have a J-Link probe, you can flash the firmware using the UF2 files generated during the build process. This method works with all setup options (Dev Container, Docker, or Native).

### Using BOOTSEL Mode (No Debug Probe Required)

1. **Enter BOOTSEL mode:**
   - Disconnect the RP2350 from USB
   - Hold down the BOOTSEL button
   - Connect USB while holding the button
   - Release the button
   - The device appears as a USB mass storage device

2. **Flash using UF2 file:**
   ```bash
   # Simple drag-and-drop method (adjust path to your build directory)
   cp docker_build/debug_flash.uf2 /media/RPI-RP2/

   # Or use picotool
   picotool load docker_build/debug_flash.uf2
   ```

### Using Picotool (Direct Upload)

Picotool can upload firmware without entering BOOTSEL mode if the device is already running compatible firmware:

```bash
# Flash debug firmware (adjust path to your build directory)
picotool load docker_build/debug_flash.uf2 -f

# Flash release firmware
picotool load docker_build/release_flash.uf2 -f

# Flash sanitize firmware
picotool load docker_build/sanitize_flash.uf2 -f

# Reboot the device after flashing
picotool reboot
```

See the [Make Targets Reference](#make-targets-reference) section for details on available build configurations.

---

## CI/CD

The project includes a GitHub Actions workflow that automatically builds firmware on every push to `master`.

Artifacts are available in the Actions tab after each build.

---

## Make Targets Reference

### Build Targets
| Command | Description |
|---------|-------------|
| `make debug` | Debug build with symbols and assertions |
| `make release_log` | Optimized build with logging enabled |
| `make release` | Fully optimized build without logging |
| `make sanitize` | Debug build with address/UB sanitizers |

### Flash Targets
| Command | Description |
|---------|-------------|
| `make flash_debug` | Flash the debug build to device |
| `make flash_release_log` | Flash the release build (with logging) |
| `make flash_release` | Flash the release build (no logging) |
| `make flash_sanitize` | Flash the sanitizer build |

### Log Targets
| Command | Description |
|---------|-------------|
| `make log_debug` | View serial output from debug build |
| `make log_release_log` | View serial output from release build |
| `make log_sanitize` | View serial output from sanitizer build |

---

## License

See [LICENSE](LICENSE) file for details.
