# Local and Cross-Platform Building Workflows

This project can be built natively or cross-compiled, subject to the
constraints below.

## Native Build Support

A **native build** is one where the build machine is also the machine that
will run the built binaries.

The following combinations of software and hardware are supported. The last
column says whether the combination is tested via CI workflow(s) on every push
and pull request to main; the others are expected to work but are not checked
with CI.

| OS | Arch | Toolchain | ABI | C runtime | Support runtime | C++ runtime | Dynamic analysis | CI |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-: |
| Linux | `x86_64` | GCC 14+ | Itanium | glibc 2.31+ | `libgcc_s` | libstdc++ | ASan, UBSan, TSan, Valgrind | yes |
| Linux | `x86_64` | Clang 18+ | Itanium | glibc 2.31+ | `libgcc_s` or compiler-rt | libstdc++ or libc++ | ASan, UBSan, TSan, MSan, libFuzzer | no |
| Linux | `aarch64` | GCC 14+ | Itanium | glibc 2.31+ | `libgcc_s` | libstdc++ | ASan, UBSan, TSan, Valgrind | yes |
| Linux | `aarch64` | Clang 18+ | Itanium | glibc 2.31+ | `libgcc_s` or compiler-rt | libstdc++ or libc++ | ASan, UBSan, TSan, libFuzzer | no |
| macOS 13+ | `arm64` | AppleClang 15+ | Itanium | libSystem | compiler-rt + libunwind | libc++ | ASan, UBSan, TSan, libFuzzer | yes |
| macOS 13+ | `x86_64` | AppleClang 15+ | Itanium | libSystem | compiler-rt + libunwind | libc++ | ASan, UBSan, TSan, libFuzzer | no |
| Windows | `x86_64` | MSVC 19.30+ (VS 2022) | MSVC | UCRT | `vcruntime140` | MSVC STL | ASan, libFuzzer | no, see notes |
| Windows | `arm64` | MSVC 19.30+ (VS 2022) | MSVC | UCRT | `vcruntime140` | MSVC STL | ASan | no, see notes |
| Windows | `x86_64` | MSYS2 UCRT64 (GCC 14+) | MinGW | UCRT | `libgcc_s_seh` | libstdc++ | None | yes |
| Windows | `x86_64` | MSYS2 CLANG64 (Clang 18+) | MinGW | UCRT | compiler-rt + libunwind | libc++ | None | no |
| Windows | `arm64` | MSYS2 CLANGARM64 (Clang 18+) | MinGW | UCRT | compiler-rt + libunwind | libc++ | None | no |

Static analysis (`clang-tidy`, `cppcheck`) and coverage instrumentation is
available for every row in the table above.

**32-bit targets** are unsupported.

**IntelLLVM** is *not listed*; it builds the project on Linux and Windows
x86_64, but adds nothing not covered by GCC and Clang.

---

### Notes on this table

**Minimum compiler versions:**

- The minimums come from `profiles/native`, which asks Conan for C++23
  (`compiler.cppstd=23`) and C23 (`compiler.cstd=23`). Conan only accepts C23
  from GCC 14 and Clang 18; GCC 13 is rejected *even though* it can compile
  most of the project.
- Conan accepts no C23 mode for MSVC at all (only C11 and C17), so the
  provided `native` profile cannot be used with MSVC. MSVC builds currently
  need a separate Conan profile without `compiler.cstd`, which has not yet been
  created. That is why the MSVC rows are not verified in CI.

**Windows:**

- `MinGW` is the only ABI this project supports that does **not** have
  built-in sanitizers.
- `MSVC` and `MSYS2` toolchains do **not** produce interchangeable object
  files, static libraries or import libraries; artifacts built by MSVC are
  **not** compatible with MSYS2, and vice versa.

**MSYS2** `MINGW64` is **unsupported.** It links `msvcrt.dll`, which has weak
C99 conformance. Use `UCRT64` for GCC or `CLANG64` for Clang.

**MSYS2** `MSYS` is **unsupported.** It is a POSIX emulation layer for the
shell; it builds binaries that depend on `msys-2.0.dll` and are **not native**
Windows programs.

## Cross-Compilation Support

A **cross build** is one where the binaries the build machine produces are
meant to run on a different machine.

These toolchain families provide different *mechanisms* for cross-compiling:

| Family | Mechanism | Compiler binaries | Sysroot |
| :-- | :-: | :-: | :-: |
| GCC | One toolchain install per target | `<triple>-gcc`, `<triple>-g++` | *Usually* bundled |
| Clang | One install, `--target=` per build | `clang`, `clang++` | Must be supplied |
| MSVC | Host/target toolset via `vcvarsall` | `cl.exe` | Not applicable |
| AppleClang | `-arch` within Apple platforms | `clang` | Bundled SDK |

Supported cross **targets** and their names:

| Target | Preset and profile name | GNU triple | Clang triple |
| :-- | :-- | :-: | :-: |
| Linux `x86_64` | `x86_64-linux-gnu` | `x86_64-linux-gnu` | `x86_64-unknown-linux-gnu` |
| Linux `aarch64` | `aarch64-linux-gnu` | `aarch64-linux-gnu` | `aarch64-unknown-linux-gnu` |
| Windows `x86_64` | `x86_64-mingw-w64` | `x86_64-w64-mingw32` | `x86_64-w64-windows-gnu` |
| Windows `aarch64` | `aarch64-mingw-llvm-w64` | `aarch64-w64-mingw32` | `aarch64-w64-windows-gnu` |

The toolchain each target expects:

| Target | Compiler executables | Toolchain | C runtime | C++ runtime | CI |
| :-- | :-- | :-- | :-: | :-: | :-: |
| Linux `x86_64` | `x86_64-linux-gnu-gcc`, `-g++` | GCC cross toolchain | glibc | libstdc++ | no |
| Linux `aarch64` | `aarch64-linux-gnu-gcc`, `-g++` | GCC cross toolchain | glibc | libstdc++ | no |
| Windows `x86_64` | `x86_64-w64-mingw32-gcc`, `-g++` | MinGW-w64 GCC, posix threads | UCRT or msvcrt, see notes | libstdc++ | yes |
| Windows `aarch64` | `aarch64-w64-mingw32-clang`, `-clang++` | llvm-mingw 20260616 (LLVM 22.1.8), UCRT build | UCRT | libc++ | yes |

Cross builds cannot run what they build. Tests are still registered with
CTest but marked `DISABLED`, unless `CMAKE_CROSSCOMPILING_EMULATOR` is set, and
turning on `ETESCA_VALGRIND` or `ETESCA_FUZZER` in a cross build stops the
configure with an error.

Code generation tools such as `etesca_codegen` run on the build machine, so a
cross build needs them built natively first. See
[Cross build](#cross-build) below.

---

### Notes on these tables

#### Target triples

A **target triple** is the ID a compiler uses for the machine the binaries
will run on. The name comes from the original three-part form, but most
modern triples have four fields:

```text
<architecture>-<vendor>-<operating system>-<environment or ABI>
x86_64       -unknown -linux             -gnu
```

- The **vendor** field is often `unknown` or `pc`, and is frequently dropped
  altogether. Debian and Ubuntu name their cross toolchains without it, which
  is why the GNU column reads `x86_64-linux-gnu`.
- The MinGW spelling is historical: in `x86_64-w64-mingw32`, `w64` is the
  vendor (the MinGW-w64 project) and `mingw32` is the operating system field,
  used for 64-bit targets too. Clang normalises it to
  `x86_64-w64-windows-gnu`, which is what `clang --version` reports.
- Both spellings in a row name the same target. Clang accepts either, and
  GNU toolchains are named after the GNU spelling.

#### MinGW-w64 C runtime

Whether an `x86_64-mingw-w64` build links UCRT or `msvcrt.dll` depends on how
that MinGW-w64 toolchain was built, not on this project. The MSYS2 `UCRT64`
toolchain targets UCRT. The MinGW-w64 packages in Debian and Ubuntu, which the
CI uses, target `msvcrt.dll` by default. Use a UCRT build of MinGW-w64 when
the binaries must match the native `UCRT64` builds.

llvm-mingw is published in UCRT and msvcrt builds; the pinned toolchain is the
UCRT build.

## Actually Building

Every build goes through the same two steps: **Conan** installs the
dependencies and writes a CMake toolchain file for one build type, then
**CMake** configures and builds with the preset that points at that toolchain
file. The build machine and build type must match between the two steps, and
the configure stops with an explanatory error when they do not.

Step-by-step guides for each build system are tracked in
[#6](https://github.com/cooldood155/end-to-end-sqlite3-in-c/issues/6) and
will be linked here as they are written. The steps below apply to every
system.

### Prerequisites

| Tool | Minimum | Why |
| :-- | :-- | :-- |
| CMake | 3.30 | `cmake_minimum_required` in the top-level `CMakeLists.txt`. |
| Ninja | any recent | The generator every profile selects. |
| Conan | 2.27 | First release that knows Clang 22, used by the llvm-mingw target. CI uses 2.32.0. |
| Python | 3.8+ | Runs Conan. |
| Git | any | Cloning, and the verify script's final report. |
| bash | 3.2+ | The helper scripts under `scripts/`. On Windows this is the MSYS2 shell. |
| A compiler | see the tables above | |

Installing them, per build machine:

**Windows, MSYS2 `UCRT64` shell:**

```bash
pacman -S --needed git \
  mingw-w64-ucrt-x86_64-toolchain \
  mingw-w64-ucrt-x86_64-cmake \
  mingw-w64-ucrt-x86_64-ninja \
  mingw-w64-ucrt-x86_64-python-pip
python -m pip install --break-system-packages "conan>=2.27"
```

**Linux, Ubuntu 24.04:**

```bash
sudo apt-get update
sudo apt-get install -y g++-14 ninja-build git pipx
pipx ensurepath
pipx install "conan>=2.27"
pipx install cmake
echo 'export CC=gcc-14 CXX=g++-14' >> ~/.bashrc
```

Ubuntu 24.04 packages CMake 3.28 and uses GCC 13 by default, both below the
minimums, so CMake comes from PyPI instead and `CC`/`CXX` select GCC 14. Open a
new shell afterwards so the `export` takes effect.

**macOS:**

```bash
xcode-select --install
brew install cmake ninja pipx
pipx ensurepath
pipx install "conan>=2.27"
```

### One-time Conan setup

Every project profile includes Conan's `default` profile, so create it once
per machine, in the same shell you will build from:

```bash
conan profile detect --force
```

On Windows with Visual Studio installed, Conan's detection prefers MSVC. From
the MSYS2 shell, force the MinGW compiler instead:

```bash
CC=gcc CXX=g++ conan profile detect --force
```

The `native` profile reads the compiler version again on every Conan run, so
upgrading a compiler never requires editing a profile. Inside MSYS2 it picks
GCC or Clang from the active environment (`UCRT64`, `CLANG64`, `CLANGARM64`);
elsewhere it honours `CC` and `CXX`.

### Build types, presets and folders

The four build types are `Debug`, `Release`, `RelWithDebInfo` and
`MinSizeRel`. Preset names use the lower-case form, for example
`native-relwithdebinfo`.

| Preset | Configure | Build | Test | Workflow | Purpose |
| :-- | :-: | :-: | :-: | :-: | :-- |
| `native-<type>` | yes | yes | yes | yes | Native build of everything. |
| `host-tools` | yes | yes | no | yes | Build-machine tools only, in Release. |
| `<cross target>-<type>` | yes | yes | no | yes | Cross build; target names from the table above. |

Where everything lands:

```text
build/<Type>/generators/                   Conan output for native builds
build/<os>-<arch>-<type>/generators/       Conan output for cross builds
build/<preset>/                            CMake build tree for that preset
build/<preset>/bin/                        executables (and DLLs on Windows)
build/<preset>/lib/                        libraries
build/host-tools/                          build-machine tools for cross builds
build/test_package/                        Conan test package builds
```

Each build type and target has its own folders, so they can all exist side
by side.

### Native build

Run everything from the repository root.

1. Install the dependencies for the build type:

   ```bash
   conan install . -pr:a profiles/native -s build_type=Debug --build=missing
   ```

   `./scripts/package.sh install --build_type=Debug` runs the same command.
   Several types at once are also possible:
   `./scripts/package.sh install --build_type=Debug,Release`.

2. Configure, build and test in one go:

   ```bash
   cmake --workflow --preset native-debug
   ```

   Or one step at a time:

   ```bash
   cmake --preset native-debug
   cmake --build --preset native-debug
   ctest --preset native-debug
   ```

The application ends up at `build/native-debug/bin/etesca`, with `.exe` on
Windows.

To switch build type, repeat both steps with the other type. Step 1 is needed
again only when the dependencies change: after editing `conanfile.py` or a
profile, or after upgrading the compiler.

### Cross build

Cross builds are driven from the build machine, so everything in
[Native build](#native-build) must already work there: the host tools and the
Conan build profile both use the native compiler.

1. Put the cross compiler on `PATH`.

   | Target | How |
   | :-- | :-- |
   | `x86_64-linux-gnu` | `sudo apt-get install g++-x86-64-linux-gnu` on a non-x86_64 Linux machine. |
   | `aarch64-linux-gnu` | `sudo apt-get install g++-aarch64-linux-gnu` |
   | `x86_64-mingw-w64` | Ubuntu: `sudo apt-get install g++-mingw-w64-x86-64`, then select the posix thread model (below). MSYS2 `UCRT64`: already present as part of the toolchain. |
   | `aarch64-mingw-llvm-w64` | Download llvm-mingw release `20260616`, UCRT build, and add its `bin` to `PATH` (below). |

   Ubuntu installs MinGW-w64 with both thread models; the posix one is needed
   for `std::thread` and related features:

   ```bash
   sudo update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix
   sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix
   ```

   llvm-mingw is published as `llvm-mingw-20260616-ucrt-x86_64.zip` for
   Windows and `llvm-mingw-20260616-ucrt-ubuntu-22.04-x86_64.tar.xz` for Linux.
   Unpack it to a fixed folder without spaces and **append** its `bin` to
   `PATH`, for example in `~/.bashrc`:

   ```bash
   export PATH="$PATH:/c/toolchains/llvm-mingw-20260616-ucrt-x86_64/bin"
   ```

   Appending matters: llvm-mingw also ships `x86_64-w64-mingw32-gcc` wrappers
   that are Clang underneath, and prepending would shadow a real MinGW-w64 GCC.
   Check the result with `aarch64-w64-mingw32-clang --version`, which must
   report Clang 22.

2. Build the host tools once, natively, in Release:

   ```bash
   conan install . -pr:a profiles/native -s build_type=Release --build=missing
   cmake --workflow --preset host-tools
   ```

   The cross presets find them in `build/host-tools` on their own.

3. Install the dependencies for the target:

   ```bash
   conan install . -pr:b profiles/native -pr:h profiles/aarch64-mingw-llvm-w64 \
     -s build_type=Release --build=missing
   ```

   `-pr:b` describes the build machine and `-pr:h` the target. The target
   profile reads the compiler version from the cross compiler itself, so an
   unexpected toolchain version fails here rather than producing mislabelled
   binaries.

4. Configure and build:

   ```bash
   cmake --workflow --preset aarch64-mingw-llvm-w64-release
   ```

The binaries end up in `build/aarch64-mingw-llvm-w64-release/bin`. Copy them to
the target machine together with the runtime files listed in
[Runtime Redistribution](#runtime-redistribution).

Replace `aarch64-mingw-llvm-w64` with any target name from the tables above,
and `Release` with any build type.

### Build options

Options are CMake cache variables, passed on the configure step:

```bash
cmake --preset native-debug -DETESCA_SANITIZE=address,undefined
```

| Option | Default | Effect |
| :-- | :-- | :-- |
| `ETESCA_BUILD_APPS` | `ON` when top-level | Build the `etesca` application. |
| `ETESCA_BUILD_TESTS` | `ON` when top-level | Build the tests. |
| `ETESCA_INSTALL` | `ON` when top-level | Generate install rules. |
| `ETESCA_WERROR` | `OFF` | Treat warnings, and analyser findings, as errors. |
| `ETESCA_LIBRARY_TYPE` | follows `BUILD_SHARED_LIBS` | `STATIC`, `SHARED`, `STATIC+SHARED` or `NONE`. The `etesca` library itself is currently always static. |
| `ETESCA_CXX_STANDARD` | `23` | Ignored when `CMAKE_CXX_STANDARD` is set, as the Conan toolchain does. |
| `ETESCA_C_STANDARD` | `23` | Ignored when `CMAKE_C_STANDARD` is set, as the Conan toolchain does. |
| `ETESCA_SANITIZE` | empty | Comma-separated: `address`, `undefined`, `thread`, `leak`, `memory`. |
| `ETESCA_HARDENING` | `ON` | Stack protection, control-flow protection and related compile and link flags. |
| `ETESCA_COVERAGE` | `OFF` | Coverage instrumentation. |
| `ETESCA_REPRODUCIBLE` | `OFF` | Remove build paths from binaries. |
| `ETESCA_LTO` | `OFF` | Interprocedural optimisation. |
| `ETESCA_CCACHE` | `ON` | Use `ccache` or `sccache` when installed. |
| `ETESCA_REDUCE_SIZE` | `ON` | Drop unused code and data at link time. |
| `ETESCA_SA_ALL` | `OFF` | Run clang-tidy and cppcheck; `ETESCA_SA_CLANG_TIDY` and `ETESCA_SA_CPPCHECK` select one. |
| `ETESCA_SA_OUTPUT` | `console` | `files` also writes a report per source file under the build tree. |
| `ETESCA_VALGRIND` | `OFF` | Also run every test under Valgrind; `ETESCA_VALGRIND_TOOL` picks the tool. |
| `ETESCA_FUZZER` | `off` | `libfuzzer` or `afl`. |

### Installing and consuming

Install a finished build to any prefix:

```bash
cmake --install build/native-release --prefix "$HOME/.local"
```

This installs the application, the library and headers, a CMake package in
`lib/cmake/etesca`, and `lib/pkgconfig/etesca.pc`. Another CMake project then
uses it with:

```cmake
find_package(etesca REQUIRED)
target_link_libraries(my_app PRIVATE etesca::etesca)
```

configured with `-DCMAKE_PREFIX_PATH="$HOME/.local"`. With pkg-config, point
`PKG_CONFIG_PATH` at `<prefix>/lib/pkgconfig` and use
`pkg-config --cflags --libs etesca`.

Archives for distribution come from CPack, run inside a build tree:

```bash
cd build/native-release
cpack
cpack --config CPackSourceConfig.cmake
```

To produce a Conan package instead, see
[`cmake/projectkit/docs/PACKAGE_SH.md`](../cmake/projectkit/docs/PACKAGE_SH.md).

### Verifying a build machine

`scripts/verify.sh` runs the whole pipeline above for every target this
machine can build, once per build type: build, all library types, tests,
install, a separate consumer project, CPack and host tools. The CI workflow
runs the same script.

```bash
./scripts/verify.sh list
./scripts/verify.sh run --build_type=Debug,Release
```

Details are in
[`cmake/projectkit/docs/VERIFY_SH.md`](../cmake/projectkit/docs/VERIFY_SH.md).

### Cleaning

```bash
./scripts/verify.sh clean
```

This removes `build/`, `stage/`, `_install/` and the `compile_commands.json`
link. It never touches the Conan cache; `./scripts/package.sh cache-clean`
does that for this package.

### Troubleshooting

| Symptom | Cause and fix |
| :-- | :-- |
| `compiler.cstd=23 is not supported by gcc 13` | GCC 13 is below the minimum. Install GCC 14 and set `CC`/`CXX` to it. |
| `compiler.cstd=23 is not supported by msvc` | Conan detected MSVC. From MSYS2, build in the `UCRT64`, `CLANG64` or `CLANGARM64` shell and re-create the default profile with `CC=gcc CXX=g++ conan profile detect --force`. |
| `Conan has not generated dependencies for 'X' yet` | Run step 1 of the build for build type `X`. |
| `ERROR: Profile not found: profiles/native` | The command was run outside the repository root. |
| `CMake 3.30 or higher is required` | The installed CMake is too old; Ubuntu 24.04's is. Install it with `pipx install cmake`. |
| `$'\r': command not found` from a script | The scripts were checked out with Windows line endings. Run `git config --global core.autocrlf false`, then check out again. |
| `Permission denied` running `./scripts/...` | The executable bits were lost, usually by downloading a zip. Run `chmod +x scripts/*.sh cmake/projectkit/scripts/*.sh`. |
| `Could not find a package configuration file provided by "etescaHostTools"` | Cross build without host tools. Run step 2 of the cross build. |
| `'None' is not a valid 'settings.compiler.version'` | The cross compiler named in the target profile is not on `PATH`. |
| `'23' is not a valid 'settings.compiler.version'` for the llvm-mingw target | A newer llvm-mingw than the pinned `20260616` release is on `PATH`. |

## Toolchain Internals

The toolchains above differ in how they are structured internally. **This
matters** when reading error messages, debugging, or trying to correct issues
that your toolchain may be causing.

| Toolchain | Driver | Preprocessor | C front-end | C++ front-end | Assembler | Linker |
| :-- | :-: | :-: | :-: | :-: | :-: | :-: |
| GCC | `gcc`, `g++` | `cpp` | `cc1` | `cc1plus` | `as` (GNU as) | `collect2` wrapping `ld` |
| Clang | `clang`, `clang++` | integrated | `clang -cc1` | `clang -cc1` | integrated (LLVM MC) | `lld`, `ld`, or `link.exe` |
| AppleClang | `clang`, `clang++` | integrated | `clang -cc1` | `clang -cc1` | integrated (LLVM MC) | `ld` (ld64 / ld-prime) |
| MSVC | `cl.exe` | `c1.dll`, `c1xx.dll` | `c1.dll` | `c1xx.dll` | integrated (`ml64.exe` standalone) | `link.exe` |

**Toolchain consequences worth knowing:**

- GCC's stages are separate processes. An error pointing at `cc1plus` came
  from the C++ front-end.
- Clang preprocesses, compiles and assembles in one process. There is no
  separate assembler step to fail.
- Clang *on* MinGW invokes GNU `ld` by default *in* MSYS2 `UCRT64`, but `lld`
  in `CLANG64`. `-fuse-ld=lld` forces the lld linker.

**Supporting tools, by family:**

| Purpose | GNU | LLVM | MSVC |
| :-- | :-: | :-: | :-: |
| Archiver | `ar`, `gcc-ar` | `llvm-ar` | `lib.exe` |
| Symbol table | `ranlib` | `llvm-ranlib` | built into `lib.exe` |
| Symbol listing | `nm` | `llvm-nm` | `dumpbin /symbols` |
| Strip | `strip` | `llvm-strip` | `/OPT:REF` at link time |
| Object copy | `objcopy` | `llvm-objcopy` | none |
| Disassembly | `objdump` | `llvm-objdump` | `dumpbin /disasm` |
| Dependency listing | `ldd` | `llvm-readelf -d` | `dumpbin /dependents` |

When cross-compiling with GNU toolchains, every one of these has a
**triple-prefixed** form (e.g., `aarch64-linux-gnu-objcopy`) and the unprefixed
*host* version **cannot** be used on target binaries. LLVM tools are
target-agnostic and need no prefix.

## Runtime Redistribution

What **must** reside alongside produced binaries, when *not statically linked*:

| Target | Files needed at runtime |
| :-- | :-- |
| Linux | `libstdc++.so.6`, `libgcc_s.so.1` (usually present) |
| macOS | None; `libSystem` and `libc++` are OS components |
| Windows MSVC | UCRT (OS component on Windows 10+), `vcruntime140.dll`, `msvcp140.dll` |
| Windows MinGW (GCC) | `libstdc++-6.dll`, `libgcc_s_seh-1.dll`, `libwinpthread-1.dll` |
| Windows MinGW (Clang) | `libc++.dll`, `libunwind.dll`, `libwinpthread-1.dll` |

MinGW binaries that run inside an MSYS2 shell but fail when launched from
Windows Explorer are almost always missing these DLLs on `PATH`. They can be
statically linked using the following flags:

```text
-static-libgcc -static-libstdc++
```

macOS provides no **static** libc and Apple does not support linking one.
