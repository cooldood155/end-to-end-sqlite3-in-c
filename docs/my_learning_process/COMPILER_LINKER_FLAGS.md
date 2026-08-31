# Common and Important GNU/MSVC Compiler and Linker Flags

`Clang/LLVM`, `Apple Clang`, `GCC` (g++/gcc), `IntelLLVM` are all
GNU-compatible compilers that support GCC/GNU language extensions, attributes,
and command-line compatibiliy flags.

`MSVC` is the **Microsoft Visual C++* proprietary compiler for C/C++ and
assembly languages used to build Windows applications.

## GNU Flags

### GNU Compiler Flags

#### GNU Debugging

- `g0`: Turns **off** debugging information, overriding any previous `-g` flag.
- `-g1`: Inludes enough data for backtraces (line numbers and function names)
  but excludes local variables.
- `g` (*`g2`*): Enables the generation of debug symbols during compilation.
- `-g3`: Generates extra debugging info, uncluding macro definitions,
  increasing file size but can be useful.
- `ggdb`: Generates **GDB** optimized debug symbols.

#### GNU Optimizations

- `-O0`: Disables optimizations completely. Default, best for fast copilation
  and accurate debugging.
- `-O1`: Basic optimization. Reduces code size and execution time without
  increasing compile time much at all.
- `-O2`: Recommended for **production**. Enables nearly all supported
  optimizations that don't have a *space-speed trade-off*.
- `-O3`: Maximum aggressive optimization. Turns on vectorization, loop
  unrolling, and inlining (can increase binary sizes).
- `-Os`: Optimizes for size; enables all -O2 optimizations that do not increase
  binary size.
- `-Ofast`: Disregards strict standards compliance (ISO, IEEE); enables -O3
  plus aggressive math optimizations which can cause precision loss.

#### GNU Warnings & Errors

- `-Wall`: Enables a broad set of commonly used warning flags.
- `Wextra`: Enables extra warning flags not covered by -Wall.
- `Werror`: Treats all compiler warnings as hard errors, stopping the build.
- `-w`: Suppress all compiler warning messages.

#### GNU Code Generation & Standards

- `-std=`: Specifies the language standard (e.g., -std=c++23, -std=c20).
- `-fPIC`: Generates position independent code, required when compiling source
  files destined for shared libraries (.so/.dll).
- `--coverage`: Instruments code to generate .gcno and .gcda files for code
  coverage analysis (gcov).

### GNU Linker Flags

*Note: To force these through the gcc/g++ front-end straight to the linker,
prepend them with `-Wl,` if not already*

- `-l<lib>`: Links a secific library by name (e.g., -lm links the math library
  libm.so/libm.dll or libm.a/libm.lib)
- `-L<dir>`: Adds a directory path to the linker's serach path for libraries.
- `shared`: Tells the linker to produce a shared objec/dynamic library instead
  of an executable.
- `static`: Forces the linker to use static libraries instead of shared ones,
  producing a self-contained binary.
- `Wl,-rpath=<dir>`: Embeds a hardcoded directory as a rutime search path
  directly into the binary for locating shared libraries at runtime.
- `Wl,--gc-sections`: Instructs the linker to remove dead (unused) functions
  and data sections to reduce binary size (must compilewith -ffunction-sections
  -fdata-sections).

---

## MSVC Flags

### MSVC Compiler Flags

#### MSVC Debugging

- `/Zi`: Standard debugging, optimized/Release builds, does **not** affect code
  optimization.
- `/ZI`: Fast iterative development, enables **edit and continue** features but
  disables many optimizations.
- `/Z7`: No separate `.pdb` is created by the compiler. Static libraries or
  distributed build systems is best use case.

#### MSVC Optimization

- `/Od`: Disables all optimizations. Default for Debugconfigurations.
- `/O1`: Optimizes code for small size. Minimizes the size of executables and
  DLLs.
- `/O2`: Optimizes code for maximum speed. Default for Release configurations.
- `/Ox`: Full optimization flag. Combines /O2 (speed), /Ob2 (inline expansion),
  /Oi (intrinsic functions), and /Ot (favor speed).

#### MSVC Warnings & Errors\

- `/W3`: Recommended production quality warning level. Displays standard warnings.
- `/W4`: Strict warning level. Displays informational warnings that can safely
  be ignored but point to potential code hazards.
- `/Wall`: Enables all warnings, including those disabled by default (can be
  noisy).
- `/WX`: Treats all compiler warnings as hard compilation errors.

#### MSVC Code Generation & Standards

- `/std:`: Specifies the C/C++ language standard (e.g., /std:c++23, /std:c20).
- `/MD`: Links the application with the multithreaded, dynamic (DLL) version of
  the C Runtime Library (MSVCRT.lib)
- `/MT`: Links the application with the multithreaded, static version of the C
  Runtime library (LIBCMT.lib).

#### MSVC Linker Flags

*Note: To pass these via the compiler command line, place them **after** the
/link switch.*

- `/SUBSYSTEM:`: Specifies the environment for the executable. Use
  `/SUBSYSTEM:CONSOLE` for command-line apps or `/SUBSYSTEM:WINDOWS` for GUI
  apps with no console window.
- `/DEBUG`: Creates a final debugging .pdb file for the executable or DLL
  containing debug symbols.
- `/DLL`: Builds a dynamic link library (.dll) as the primary output.
- `/LIBPATH:<dir>`: Adds a directory path to the linker's serach path for .lib
  files.
- `/OPT:REF`: Eliminates functions and data that are never referenced;
  significantly shrinks final binary sizes.
- `/OPT_ICF`: Performs identical COMDAT folding. Merges duplicate redundant
  code/data sections to optimize memory.
