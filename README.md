# portable pytyhon3-apt
> A lightweight Bash build tool for assembling portable Debian APT and Python runtime dependencies

[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)
[![Debian: 13](https://img.shields.io/badge/Debian-13%20%28Trixie%29-red.svg)](https://www.debian.org/releases/trixie/)
[![Bash](https://img.shields.io/badge/Bash-4%2B-4EAA25.svg)](https://www.gnu.org/software/bash/)

---

**Debian Mirror Dependency Grabber** downloads selected Debian packages directly from a configurable mirror, extracts them without installing them on the host system, collects the required runtime libraries and Python APT components, configures ELF `RPATH`, and builds the required Python native modules.

The project is currently configured around **Debian 13 (Trixie)** and **Python 3.13**.

---

## ✨ Features

* **📦 Direct `.deb` Download** — Downloads specific Debian packages directly from the configured mirror.
* **🔓 Non-invasive Extraction** — Extracts packages with `dpkg-deb` instead of installing them into the host system.
* **🎯 Selective Library Collection** — Copies only the libraries defined by the project's dependency set.
* **🐍 Python 3.13 Integration** — Bundles the Python 3.13 runtime library and development headers.
* **📦 APT Python Support** — Collects `python3-apt`, `apt_pkg`, and `apt_inst` components.
* **🛠️ ELF RPATH Patching** — Uses `patchelf` to make bundled libraries resolve dependencies relative to the bundle.
* **⚙️ Cython Compilation** — Converts Python APT modules from `.py` to C and then compiles them into shared objects.
* **🏗️ Architecture-aware Output** — Generates output under `build/<architecture>/`.
* **🔧 Configurable Compiler** — Supports selecting native or cross-compilation toolchains through `conf.sh`.
* **🧹 Automatic Cleanup** — Removes temporary package and extraction directories after completion.
* **🎛️ Fully Script-configurable** — Debian mirror, architecture, compiler, Python version, and build paths are configurable.

---

## 📋 Requirements

The build environment requires:

| Dependency                           | Purpose                                             |
| ------------------------------------ | --------------------------------------------------- |
| `bash`                               | Runs the build scripts                              |
| `curl`                               | Downloads Debian `.deb` packages                    |
| `dpkg-deb`                           | Extracts Debian packages                            |
| `patchelf`                           | Configures ELF `RPATH`                              |
| `cython`                             | Converts Python modules to C                        |
| `gcc` or another configured compiler | Builds generated C modules                          |
| Python 3.13 development files        | Provides Python headers and libraries               |
| `libnew_shell`                       | Provides shell helper functions used by the project |

### Debian / Ubuntu

On Debian-based systems, the main external build tools can be installed with:

```bash
sudo apt install curl dpkg-dev patchelf cython3 gcc
```

The project also expects [`libnew_shell`](https://github.com/KAZ-CORE/libnew_shell) to be available because the main build script sources it directly:

```bash
source libnew_shell
```

---

## ⚙️ Configuration

The project uses `conf.sh` as its configuration file.

The default configuration is:

```bash
# Target architecture
arch="amd64"

# Compiler
CC="gcc"

# Debian mirror
address_mirror="https://deb.debian.org/debian"
```

### `arch` — Target Architecture

Defines the architecture used when constructing Debian package URLs and the output directory.

```bash
arch="amd64"
```

Typical values include:

| Value   | Architecture          |
| ------- | --------------------- |
| `amd64` | x86-64                |
| `i386`  | x86 32-bit            |
| `armhf` | ARM 32-bit hard-float |
| `arm64` | AArch64               |

The generated output path is derived automatically:

```text
build/<architecture>/
```

For example:

```text
build/amd64/
```

---

### `CC` — Compiler

Defines the compiler used to build the generated native Python modules.

For a native build:

```bash
CC="gcc"
```

For a cross-compilation toolchain:

```bash
CC="aarch64-linux-gnu-gcc"
```

or:

```bash
CC="arm-linux-gnueabihf-gcc"
```

or:

```bash
CC="i686-linux-gnu-gcc"
```

The compiler must match the selected target architecture.

---

### `address_mirror` — Debian Mirror

Defines the Debian mirror used to download the required packages.

Default:

```bash
address_mirror="https://deb.debian.org/debian"
```

A different Debian mirror can be selected when required:

```bash
address_mirror="https://ftp.de.debian.org/debian"
```

---

## 🧠 Advanced Configuration

The remaining settings are primarily intended for development and build customization.

```bash
# Python version
version_python=3.13

# Compiler flags
CC_FLAGS="-shared -O3 -fPIC -I./include -I./include/python${version_python} -L./lib -lpython${version_python} -Wl,-rpath,\$ORIGIN/lib"

# Internal paths
path_origin="$(pwd)"
build="build"
extracted_libs=".extracted_libs"
path_temp_deb=".tmp_deb"
path_target="build/${arch}"
path_target_lib="${path_target}/lib"
path_lib_apt="${path_target}/apt"
```

### Configuration Variables

| Variable          | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `version_python`  | Python version used by the build                       |
| `CC_FLAGS`        | Compiler and linker flags for generated native modules |
| `path_origin`     | Original project working directory                     |
| `build`           | Base build directory                                   |
| `extracted_libs`  | Temporary extracted package tree                       |
| `path_temp_deb`   | Temporary directory containing downloaded `.deb` files |
| `path_target`     | Final architecture-specific output directory           |
| `path_target_lib` | Destination for collected shared libraries             |
| `path_lib_apt`    | Destination for Python APT native modules              |

---

## 🚀 Usage

### Basic Build

Configure `conf.sh`:

```bash
cat > conf.sh << 'EOF'
arch="amd64"
CC="gcc"
address_mirror="https://deb.debian.org/debian"
EOF
```

Make the script executable:

```bash
chmod +x get_mirror_deps.sh
```

Run the builder:

```bash
./get_mirror_deps.sh
```

A successful build produces:

```text
build/amd64/
```

---

## 🔧 Cross-Compilation

The compiler and target architecture can be changed through `conf.sh`.

For example, an ARM64 build can use:

```bash
arch="arm64"
CC="aarch64-linux-gnu-gcc"
address_mirror="https://deb.debian.org/debian"
```

Then run:

```bash
./get_mirror_deps.sh
```

The generated files will be placed under:

```text
build/arm64/
```

The appropriate cross-compilation toolchain must be installed before running the build.

For example:

```bash
sudo apt install gcc-aarch64-linux-gnu
```

---

## 📂 Output Structure

A typical `amd64` build produces a directory similar to:

```text
build/
└── amd64/
    ├── apt/
    │   ├── apt_pkg.cpython-313-*.so
    │   ├── apt_inst.cpython-313-*.so
    │   └── ...
    │
    ├── lib/
    │   ├── libapt-pkg.so.7.0
    │   ├── libbz2.so.1.0
    │   ├── libcap.so.2
    │   ├── libcrypto.so.3
    │   ├── libexpat.so.1
    │   ├── libgcc_s.so.1
    │   ├── liblz4.so.1
    │   ├── liblzma.so.5
    │   ├── libpython3.13.so*
    │   ├── libstdc++.so.6
    │   ├── libsystemd.so.0
    │   ├── libudev.so.1
    │   ├── libxxhash.so.0
    │   ├── libz.so.1
    │   └── libzstd.so.1
    │
    └── include/
        └── ...
```

The exact contents depend on the configured architecture and the files contained in the selected Debian packages.

---

## 🔍 Dependency Set

The current build script explicitly retrieves the following Debian packages:

```text
libpython3.13
libpython3.13-dev
python3-apt
libc6
libstdc++6
libgcc-s1
libapt-pkg7.0
libbz2-1.0
liblzma5
liblz4-1
libzstd1
libudev1
libsystemd0
libssl3t64
libxxhash0
libexpat1
libcap2
zlib1g
```

The package versions are explicitly pinned in `get_mirror_deps.sh` and currently target Debian 13.

---

## 🔧 How It Works

The build pipeline is intentionally straightforward:

```text
Debian Mirror
     │
     ▼
Download .deb packages
     │
     ▼
Extract with dpkg-deb
     │
     ▼
Select required libraries
     │
     ├──► lib/
     │
     ├──► apt/
     │
     └──► include/
     │
     ▼
Patch ELF RPATH
     │
     ▼
Cython: .py → .c
     │
     ▼
Compiler: .c → .so
     │
     ▼
Remove temporary files
     │
     ▼
build/<architecture>/
```

### 1. Download

The `get_deb()` function constructs the Debian package URL from the configured mirror, package path, package name, version, and architecture.

Packages are downloaded into the temporary package directory.

### 2. Extract

Each downloaded `.deb` file is extracted with:

```bash
dpkg-deb -x
```

The package is therefore processed as an archive rather than installed into the host package database.

### 3. Collect Libraries

The script maintains an internal `lib_used` set containing the libraries it expects to bundle.

Matching files are copied from the extracted package tree into:

```text
build/<architecture>/lib/
```

### 4. Collect APT Components

The extracted `python3-apt` package is inspected for:

```text
/usr/lib/python3/dist-packages/apt/
/usr/lib/python3/dist-packages/apt_pkg*.so
/usr/lib/python3/dist-packages/apt_inst*.so
```

These files are copied into the target output.

Available headers under:

```text
/usr/include
```

are also copied into the output tree.

### 5. Patch RPATH

Every collected shared library is processed with `patchelf`:

```bash
patchelf --force-rpath --set-rpath '$ORIGIN' <library>
```

The Python APT native modules are configured with:

```text
$ORIGIN/../lib
```

This makes the generated bundle reference its local library directory.

### 6. Compile Python Modules

Python files under:

```text
apt/
apt/progress/
```

are converted into C with Cython:

```text
.py → .c
```

The resulting C files are compiled into shared objects using the configured compiler:

```text
.c → .so
```

Temporary generated `.c` files are removed after compilation.

### 7. Cleanup

The temporary package directory and extracted filesystem are removed after the required files have been collected.

---

## 🧪 Troubleshooting

| Problem                                      | Possible Cause                                                                            |
| -------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `404 Not Found`                              | Package name, path, version, architecture, or mirror does not match the Debian repository |
| Download failure                             | Network or mirror availability issue                                                      |
| `dpkg-deb` extraction failure                | Invalid or incomplete `.deb` package                                                      |
| `patchelf: command not found`                | `patchelf` is not installed                                                               |
| `cython: command not found`                  | Cython is not installed or not available in `PATH`                                        |
| Compiler error                               | Incorrect compiler, headers, architecture, or linker configuration                        |
| `error while loading shared libraries`       | A required shared library was not included in the generated bundle                        |
| `ModuleNotFoundError: No module named 'apt'` | The generated `apt` package directory is not on the Python module search path             |
| Cross-compilation failure                    | The selected compiler/toolchain does not match the configured target architecture         |

---

## 📝 Debian Compatibility

The current package definitions are designed around:

```text
Debian 13 (Trixie)
Python 3.13
```

The package versions are explicitly specified in the build script.

Moving to another Debian release may require updating:

* Package versions
* Package paths
* APT package versions
* Python version
* Library names
* Compiler configuration
* Output expectations

The project should therefore be treated as **Debian 13-oriented** unless the dependency definitions are updated for another release.

---

## 🗂️ Project Files

The core project consists of:

```text
.
├── conf.sh
├── get_mirror_deps.sh
└── libnew_shell
```

### `get_mirror_deps.sh`

Main build script responsible for downloading packages, extracting dependencies, collecting libraries, configuring RPATH, compiling Python modules, and cleaning temporary data.

### `conf.sh`

Build configuration containing architecture, compiler, Debian mirror, Python version, compiler flags, and internal output paths.

### `libnew_shell`

Shell helper library used by the build script for colored output and logging utilities.

---

## 📄 License

This project is licensed under the:

**GNU General Public License v2.0 (GPL-2.0)**

```text
Copyright (C) 2026 KAZ-CORE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation, either version 2 of the License,
or (at your option) any later version.
```

See [`LICENSE`](LICENSE) for the complete license text.

---

## 🤝 Contributing

Contributions are welcome.

When contributing:

1. Keep the build process reproducible.
2. Avoid unnecessary changes to the host system.
3. Keep architecture-specific behavior configurable.
4. Document changes to package versions.
5. Test changes against the intended Debian release.
6. Keep dependency collection explicit and reviewable.

For larger changes, please open an issue first to discuss the proposed approach.

---

## ⚠️ Disclaimer

This project downloads packages from Debian repositories and redistributes selected files from those packages into a generated bundle.

Users are responsible for complying with the licenses and redistribution requirements applicable to the packages and files they use.

The project itself is licensed under GPL-2.0; Debian packages and their individual components may be distributed under different licenses.

---

## 🙏 Acknowledgments

This project makes use of and relies on the following open-source projects:

* [Debian](https://www.debian.org/)
* [Cython](https://cython.org/)
* [patchelf](https://github.com/NixOS/patchelf)
* [libnew_shell](https://github.com/KAZ-CORE/libnew_shell)

---

**Made with ❤️ for Debian, Bash, and portable software tooling.**
