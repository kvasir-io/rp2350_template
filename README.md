# RP2350 Template

A template project for RP2350 development using the Kvasir SDK.

## Setup Options

You can set up this project in three ways: using VSCode Dev Containers (easiest), Docker with manual setup, or native development.

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
   ./scripts/docker.sh start
   ```

2. **Attach to the container:**

   ```bash
   ./scripts/docker.sh attach
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
./scripts/docker.sh start

# Attach to running container (from terminal)
./scripts/docker.sh attach

# Stop container
./scripts/docker.sh stop
```

**Windows users (PowerShell):** Use `.\scripts\docker.ps1` instead:

```powershell
# Start container
.\scripts\docker.ps1 start

# Attach to running container
.\scripts\docker.ps1 attach

# Stop container
.\scripts\docker.ps1 stop
```

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

### Build Output

After building, you'll find the firmware files in the build directory:
- `*.uf2` - Drag-and-drop firmware for RP2350
- `*.elf` - Debugging symbols
- `*.bin` / `*.hex` - Raw firmware binaries
- `*.map` / `*.lst` - Memory map and assembly listings

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
