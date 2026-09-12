# `cmake/TestCreator.cmake` Documentation

As the name suggests (sort of), this module provides functionality for
creating Catch2 test executables for libraries created by
`cmake/LibraryCreator.cmake`. This module also provides a function for reading
from a global list of test targets.

Tests are **opt-in per library**. Nothing is generated for a library until
`etesca_create_test` is called for it, building the project does not mean
building and running every test in it. Test sources live in
`tests/<library_name>/` and are collected recursively, so adding a test file
never requires editing a CMake file!

## What `TestCreator` Provides

This module provides functions only; **two functions** are defined, both are
intended to be used directly.

### `etesca_create_test`

Creates one test executable per variant of the named library, collects the
test sources for it, links it against that variant, and registers the
resulting Catch2 test cases with CTest.

A library built as STATIC+SHARED produces two test executables from the same
sources, one linked against each variant. This is deliberate: the static and
shared builds differ in their export macros and in
`<LIBRARY_NAME>_STATIC_DEFINE`, so a break in one will not always show up in
the other and this is **needed to surface them**.

#### Parameters

**Options:**

- `NO_DEFAULT_LINKS`: Suppresses the automatic `etesca::warnings` and
  `etesca::options` links, for a test executable that **must** opt out of
  them.
- `NO_VALGRIND`: Skips `etesca_add_valgrind_test` for this library, for a
  suite where running under Valgrind is too slow to be worth it.

**One Value:**

- `NAME`: This is the name of the library to create tests for, it is
  **required**. It must match the `NAME` given to `etesca_create_library`.
- `SOURCE_DIR`: This is the directory containing the test sources, if it is
  not provided it is set to the default `"${PROJECT_SOURCE_DIR}/tests/${NAME}/"`
  directory.
- `LABEL`: The CTest label applied to every discovered test case, if it is not
  provided it is set to `unit`. Labels are what `ctest -L` filters on.

**Multi Value:**

- `SOURCES`: This is a list of full paths of test sources to be added to the
  executable. Anything found in `SOURCE_DIR` is appended to it.
- `LINK_PRIVATE`: Additional libraries to link into the test executable, for
  dependencies needed by the tests but not by the library itself.

**Example Usage:**

```cmake
find_package(Catch2 3 REQUIRED)
include(Catch)

etesca_create_test(NAME etesca)

etesca_create_test(
  NAME mixed
  LABEL integration
  NO_VALGRIND
  LINK_PRIVATE etesca::test_fixtures)
```

#### Created Targets

The target name is gotten from the library variant being tested.

- *If the library was built as STATIC+SHARED*: two executables are created,
  `"${NAME}_tests_static"` and `"${NAME}_tests_shared"`.
- *Otherwise*: one executable is created, `"${NAME}_tests"`.

Each created target is appended to the global list of test targets
(`ETESCA_TEST_TARGETS`), readable through  the `get_global_tests` function.

#### Errors

This function stops configuration rather than producing a silently empty or
mislinked suite:

- If `catch_discover_tests` is not defined, meaning
  `find_package(Catch2 3 REQUIRED)` and `include(Catch)` have not been called.
- If no test sources are found in `SOURCE_DIR` and none were given via
  `SOURCES`.
- If no library targets match `NAME`, meaning `etesca_create_library` was
  either not called for it or was called after this function or in someway
  misbehaved.

#### Cross Compilation

When `CMAKE_CROSSCOMPILING` is set and no `CMAKE_CROSSCOMPILING_EMULATOR` is
available, the executables cannot be run on the build machine. Each test is
still registered with CTest, but as a single `DISABLED` test rather than
through Catch2 discovery, because discovery works by executing the binary.

### `get_global_tests`

Used to retrieve the list of stored test targets from the
`ETESCA_TEST_TARGETS` global variable, appended to via `etesca_create_test`.

#### Parameters

**Positional:**

- `OUTPUT_VAR`: The name of the variable returned to `PARENT_SCOPE` containing
  the list of test targets.

**Example Usage:**

```cmake
get_global_tests(out_tests)
```

## Practical Usage

You normally should only be using the `etesca_create_test` function like so:

```cmake
# tests/CMakeLists.txt
find_package(Catch2 3 REQUIRED)
include(Catch)

etesca_create_test(NAME etesca)
```

The matching layout is:

```plaintext
tests/
├── CMakeLists.txt
└── etesca/
    ├── tests_core.cpp
    └── parser/
        └── tests_parser.cpp
```

## Notes

*Note:* This module depends on `etesca_link_target` and
`get_global_libraries` from `cmake/LibraryCreator.cmake`, and reads the global
library list that `etesca_create_library` writes to. It must therefore be
included after `cmake/LibraryCreator.cmake`, and every `etesca_create_test`
call must come after the `etesca_create_library` call it refers to.
