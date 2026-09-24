# Changelog

All notable changes to this project, **directly impacting users** or
**downstream developers**, are recorded here; changes impacting a person or
persons who will use the final produced binary or binaries in any noticable
manner are logged and scoped to a release version.

The format is [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and
the version numbers follow [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## What is logged

A change is notable when a user of the produced binaries could notice it
without reading the source. New or altered behaviour, new or removed build
options, changed defaults, supported-platform changes, etc.

Refactors, formatting, test-only changes, CI configuration, and internal
build-system work does not get logged here. The git history records those
commits. However, a refactor that changes observable behavior is a behavior
change, and is logged as such.

## Who logs it

The author of the change, in the **same pull request** that makes the change.
*Reviewers* treat a missing enty the same as a missing test: a reason to
request changes.

## When to log it

**At the time the change is written**, not at release time. Reconstructing a
release's worth (or commits worth) of log entries from commit message entries
will simply produce logs less descriptive and reliable than the git commit
messages themselves, exactly what is trying to be avoided.

## Where to log it

Under the `## [Unreleased]` section, in the sub-section that accurately
describes the change. *For example*, a bug that was fixed without adding new
"maningful logic" (explained below) belongs under `### Fixed` and **should** be
tracked. **Meaningful logic** is any piece of *code* exposing new business
logic or functionality:

| Sub-section | Use for |
| :-- | :-- |
| `### Added` | New functionality. |
| `### Changed` | Altered behaviour of existing functionality. |
| `### Deprecated` | Functionality still present but slated for removal. |
| `### Removed` | Functionality deleted in this release. |
| `### Fixed` | Bug fixes that add no meaningful logic. |
| `### Security` | Vulnerabilities addressed. |

## Why it matters

A changelog is written for users/people who consume the project, so that (for
example) when they are deciding whether to upgrade, doing so and it failing,
and then finding out what changed causing it to break after upgrading, does not
require reading diffs. Semantic Versioning tells a consumer that a release is
is breaking; only the changelog tells them *what* broke and what to do about
it.

## How to log it

One entry per change, as a Markdown list item under the appropriate
sub-section. Write a complete sentence in the **past tense**, ending in a
period, and describing the effect on the user instead of the implementations
introduced:

```markdown
## [Unreleased]

### Added

- Added `--strict` to reject malformed input instead of repairing it.

### Fixed

- Fixed a crash when the input file was empty. ([#42](...))
```

Reference an issue and/or pull request where one exists. Delete any sub-section
that has no entries at release time; empty headings in a published release are
a waste of space and makes the document harder to follow.

## How to *cut* a release

Replace the `[Unreleased]` heading with the version and the release date in
`YYYY-MM-DD` form, keeping the brackets, then add a fresh
`[Unreleased section]` above it:

```markdown
## [Unreleased]

## [1.0.0] - 2026-09-02
```

Newest releases are placed at the top. Each release version is linked to the
GitHub repository tag it belongs to.

---

## [Unreleased]

### Added

- Added cross-compilation configure, build and workflow presets for
  `x86_64-linux-gnu`, `aarch64-linux-gnu`, `x86_64-mingw-w64` and
  `aarch64-mingw-llvm-w64`, each in `Debug`, `Release`, `RelWithDebInfo` and
  `MinSizeRel`. ([#4])
- Added `scripts/verify.sh`: configures, builds, tests, installs, packages and
  consumes the project for every native and cross target available on the host,
  once per requested build type. ([#4])
- Added `scripts/package.sh`: Entry point for Conan 2 package management
  (`install`, `create`, `list`, `editable`, `remove`, `upload` and more). Its
  `create` command also builds and runs a test package against the packaged
  result. ([#4])
- Added the `ETESCA_SA_LAUNCHER` cache variable to replace the old wrapper
  script used when `ETESCA_SA_OUTPUT` is set to `files`. ([#4])
- Added `COMPONENTS` support to the installed package config. Each requested
  component is reported as found when the matching `etesca::<component>`
  target is exported. ([#4])
- Added native and cross build instructions to `docs/BUILDING.md`, including
  which build machines and targets are verified in CI. ([#6])

### Changed

- Changed the `etesca` library to depend on SQLite3. `find_package(etesca)`
  now also finds `SQLite3`, which must be available to consumers.
- Changed configuration to require a `CMAKE_BUILD_TYPE` with matching Conan
  output. Configuring without a build type, with an unknown build type, before
  `conan install` has run for that build type, or with Conan output generated
  for a different build type will now stop with an explanatory error.
  Build type names are now also matched case-insensitively. ([#4])
- Changed the `etesca` library to always build as a static library.
  `ETESCA_LIBRARY_TYPE` and `BUILD_SHARED_LIBS` no longer change its linkage
  and the `etesca::static` and `etesca::shared` targets are no longer exported.
  ([#4])
- Changed `ETESCA_CXX_STANDARD` and `ETESCA_C_STANDARD` to defer to
  `CMAKE_CXX_STANDARD` and `CMAKE_C_STANDARD` when those are already set, just
  as the Conan toolchain does. ([#4])
- Changed the Conan profiles to read `compiler.version` from the installed
  compiler on every run instead of using a fixed or previously detected value.
  A toolchain upgrade can no longer produce mislabelled binaries. Inside MSYS2
  the `native` profile now selects GCC or Clang from the active environment.
  ([#4])
- Changed the `native` Conan profile to request C23, raising the minimum native
  compiler to GCC 14 or Clang 18. MSVC can no longer use the `native` profile,
  because Conan doesn't accept C23 mode for MSVC. ([#4])
- Changed the `aarch64-mingw-llvm-w64` target to require llvm-mingw built on
  LLVM 22 (release 20260616, LLVM 22.1.8). ([#4])
- Changed the `native` Conan profile to set `tools.build:skip_test=False`, so
  tests are built even when your default profile disables them. ([#4])
- Changed the `x86_64-mingw-w64` profile to stop passing `-mucrt`. Cross-built
  Windows binaries now use the toolchain's default C runtime, which is
  `msvcrt.dll` unless the MinGW-w64 toolchain is itself a UCRT build. ([#4])
- Changed the cross presets to be available on every host instead of Linux
  only and to find host tools in `build/host-tools` instead of
  `build/native-release`. ([#4])

### Fixed

- Fixed the CMake package files (`etescaConfig.cmake`,
  `etescaConfigVersion.cmake`, `etescaTargets.cmake`) and `etesca.pc` not
  being installed. They were previously generated only when a fuzzer was
  enabled and used a malformed path. They are now installed whenever
  `ETESCA_INSTALL` is on and a library is built. ([#4])
- Fixed `etesca::etesca` resolving to the static version when the consumer set
  `BUILD_SHARED_LIBS` to on/true, and to the shared version when it was
  off/false. ([#4])
- Fixed the check for a Conan `shared` option not working with the cached
  `BUILD_SHARED_LIBS`; Conan was writing the intent file with the wrong name.
  ([#4])
- Fixed the `host-tools` build and workflow presets configuring the
  `native-release` configuration instead of the host-tools-only configuration.
  ([#4])
- Fixed `compile_commands.json` not being linked to the source tree when
  configuring using a CMake preset. A failure to link it is now a warning
  instead of a configure error. ([#4])
- Fixed `ETESCA_VALGRIND` tests not running Valgrind at all. They now run the
  tool selected by `ETESCA_VALGRIND_TOOL` and fail on any reported error.
  ([#4])
- Fixed configuring with `ETESCA_FUZZER=afl` failing on an unknown CMake
  command. ([#4])
- Fixed `ETESCA_SA_OUTPUT=files` with clang-tidy trying to use a launcher
  script that did not exist. ([#4])
- Fixed native configures with static analysis enabled failing on a
  misspelled codegen target name. ([#4])

[#4]: https://github.com/cooldood155/end-to-end-sqlite3-in-c/pull/4
[#6]: https://github.com/cooldood155/end-to-end-sqlite3-in-c/issues/6
