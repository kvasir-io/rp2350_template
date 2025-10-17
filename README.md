# RP2350 Template

A template project for RP2350 development using the Kvasir SDK.

## Setup Options

You can set up this project in two ways: using Docker with VSCode (recommended for easy setup) or native development with Clang 20+.

---

## Option 1: Docker Development (Recommended)

This setup uses Docker to provide a pre-configured build environment with all dependencies included.

### Prerequisites

- Docker installed on your system

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

   This will build all configurations. You can also use make targets directly:

   ```bash
   cd /workspace/project/docker_build

   # Build specific configurations
   make debug
   make release_log
   make sanitize

   # Flash firmware
   make flash_debug
   make flash_release_log

   # View serial output
   make log_debug
   make log_release_log
   ```

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

## Option 1B: VSCode with Docker (IDE Integration)

If you prefer using VSCode with IDE features, you can attach VSCode to the running Docker container.

### Additional Prerequisites

- VSCode with the **Dev Containers** extension installed

### Steps

1. **Start the Docker container** (if not already running):

   ```bash
   ./scripts/docker.sh start
   ```

2. **Attach VSCode to the running container:**
   - Open VSCode
   - Press `F1` or `Ctrl+Shift+P`
   - Run command: `Dev Containers: Attach to Running Container...`
   - Select the `rp2350-rp2350_template` container

3. **Open the project folder** inside the container:
   - `/workspace/project`

4. **Build your project** using VSCode tasks:
   - Press `Ctrl+Shift+P` → `Tasks: Run Build Task`
   - Or use the predefined tasks: Build, Flash, Log

---

## Windows-Specific Setup for Flashing/Debugging

Windows Docker Desktop does not expose the USB subsystem to containers, so you cannot directly flash or debug from inside the Docker container. To work around this, you need to use **JLinkRemoteServer** running on your Windows host.

### Prerequisites

- [SEGGER J-Link Software](https://www.segger.com/downloads/jlink/) installed on Windows
- JLinkRemoteServer (included with J-Link Software)

### Steps

1. **Start JLinkRemoteServer on Windows:**

   - Open a Command Prompt or PowerShell
   - Run: `JLinkRemoteServer.exe`
   - Leave it running in the background
   - It will listen on port 19020 by default

2. **Configure the project to use the remote J-Link:**

   **Option A: For command-line builds:**

   When running cmake, add the JLINK_IP variable:

   ```bash
   cmake .. -DJLINK_IP=host.docker.internal
   ```

   **Option B: For VSCode (inside Docker container):**

   Edit `.vscode/settings.json` and uncomment these lines:

   ```json
   "cmake.configureArgs": [
     "-DJLINK_IP=host.docker.internal"
   ],
   ```

3. **Flash and debug as normal:**

   The flash and debug commands will now connect to the JLinkRemoteServer running on your Windows host via the special `host.docker.internal` hostname.

### Notes

- `host.docker.internal` is a special DNS name that resolves to the host machine's IP from inside Docker Desktop
- JLinkRemoteServer must be running whenever you want to flash or debug
- This setup works for both command-line and VSCode workflows

---

## Option 2: Native Development (Without Docker)

This setup requires manual installation of dependencies but gives you full control.

### Prerequisites

- **Clang 20+** (required)
- **CMake 3.28+**
- **Git**

### Steps

1. **Clone the required Kvasir repositories:**

   ```bash
   # Create a directory for Kvasir dependencies
   mkdir kvasir_deps
   cd kvasir_deps

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
   cd /path/to/rp2350_template

   # Create build directory
   mkdir build
   cd build

   # Configure with CMake
   cmake .. \
     -DKVASIR_ROOT=/path/to/kvasir_deps/Kvasir_SDK \
     -DUSE_FORCE_FETCH=ON \
     -DCMAKE_C_COMPILER=clang \
     -DCMAKE_CXX_COMPILER=clang++
   ```

3. **Build the project:**

   ```bash
   cmake --build . --parallel $(nproc)
   ```

4. **View serial output (optional):**

   After flashing your firmware, you can view the serial output:

   ```bash
   # For debug build
   make log_debug

   # For release build with logging
   make log_release_log

   # For sanitize build
   make log_sanitize
   ```

### Build Output

After building, you'll find the firmware files in the build directory:
- `*.uf2` - Drag-and-drop firmware for RP2350
- `*.elf` - Debugging symbols
- `*.bin` / `*.hex` - Raw firmware binaries
- `*.map` / `*.lst` - Memory map and assembly listings

---

## VSCode Tasks

The project includes predefined tasks for common operations:

- **Build** - Compile the project (prompts for configuration)
- **Flash** - Flash firmware to device (prompts for configuration)
- **Log** - View serial output (prompts for configuration)

Available configurations:
- Debug
- Release (with logging)
- Release (no logging)
- Sanitize

Access tasks via `Ctrl+Shift+P` → `Tasks: Run Task`

---

## Debugging

Two launch configurations are available:

1. **Flash and Debug** - Flashes firmware then attaches debugger
2. **Attach Only** - Just attaches to running device

Both require a J-Link debugger connected to your RP2350.

Press `F5` to start debugging.

---

## CI/CD

The project includes a GitHub Actions workflow that automatically builds firmware on every push to `master`.

Artifacts are available in the Actions tab after each build.

---

## Project Structure

```
.
├── src/                    # Source code
├── scripts/                # Build and Docker scripts
├── .vscode/                # VSCode configuration
├── .github/workflows/      # CI/CD configuration
└── CMakeLists.txt          # CMake configuration
```

---

## License

See [LICENSE](LICENSE) file for details.
