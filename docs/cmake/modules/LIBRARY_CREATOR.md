# `cmake/LibraryCreator.cmake` Documentation

As the name suggests, this module provides functionality for creating CMake
libraries. This module also provides functions for appending to and reading
from a global list of library targets.

CMake libraries work like packages, grouping source files, header files, and
build settings into reusable units. You can choose to create header only
libraries, source only libraries, settings only libraries ("Interface"), or any
combination of them.

## What `LibraryCreator` Provides

This module provides functions only; **seven functions** are defined, only a
few are used.

### `append_global_libraries`

This function can be used to append a single library target to the globally
maintained list (`ETESCA_LIBRARY_TARGETS`), or create the global list and add
the value passed to it.

#### Parameters

**Multi Value:**

- `TARGETS:` This is a list of library targets to be appended to the list.

**Example Usage:**

```cmake
add_library(MyLib STATIC main.cpp)

append_global_libraries(TARGETS MyLib)
```

*Note:* Each library configured with `etesca_create_library` is automatically
appended to the global libraries list.

### `etesca_add_library` *(internal)*

Responsible for adding the libraries and *namespace aliases*
(e.g., etesca::etesca), and returning two variables to the parent scope.

#### Parameters

**Positional:**

- `NAME`: Name of the library; must be the first argument passed. If a
  static+shared library is being built, then the libraries have '_static' and '_shared' appended to them respectively.

**One Value:**

- `KIND` (required): One of `COMPILED`, `HEADER_ONLY` or `INTERFACE`.
  `COMPILED` obeys `LINKAGE`; the other two produce a single `INTERFACE`
  target and no export header target.
- `LINKAGE` (required for `COMPILED`): One of `STATIC`, `SHARED` or
  `STATIC+SHARED`. This function never reads `ETESCA_LIBRARY_TYPE` itself; the
  caller resolves it and passes the result in.

**Multi Value:**

- `SOURCES`: These are the list of sources to add to the library, it is
  required for `KIND` `COMPILED`.

**Example Usage:**

```cmake
etesca_add_library(etesca
  KIND    COMPILED
  LINKAGE SHARED
  SOURCES
    "${CMAKE_SOURCE_DIR}/src/etesca/main.cpp"
    "${CMAKE_SOURCE_DIR}/include/etesca/main.hpp")
```

#### Returned Variables

The two returned variable identities are `${NAME_UPPER}_LIBRARY_TARGETS` and
`${NAME_UPPER}_EXPORT_HEADER_TARGET`, where `${NAME_UPPER}` is the uppercased
string variant from the passed in `NAME` argument.

- `${NAME_UPPER}_LIBRARY_TARGETS`

  This is a list of library targets, appended to depending on the type of
  library specified.

  - *If `LINKAGE` is `STATIC+SHARED`*: The following two libraries are
    appended: `"${NAME}_static"` and `"${NAME}_shared"`.

  - *If `LINKAGE` is `SHARED`*: The following library is appended: `${NAME}`,
    representing a shared library.

  - *If `LINKAGE` is `STATIC`*: The following library is appended: `${NAME}`,
    representing a static library.

  - *If `KIND` is `HEADER_ONLY` or `INTERFACE`*: The following library is
    appended: `${NAME}`, representing an interface library.

- `${NAME_UPPER}_EXPORT_HEADER_TARGET`

  This is the single target that `generate_export_header` should be run
  against. It is empty for `HEADER_ONLY` and `INTERFACE` libraries, as an
  interface library compiles no translation unit and so has nothing to export.

### `etesca_collect_components` *(internal)*

Recursively combs through the passed in source directory and include directory
for all C and C++ source/header files. If no sources or headers are found, a
`FATAL_ERROR` message can optionally be sent out.

#### Parameters

**Positional:**

- `NAME`: The name of the library components are being collected for, currently
  only serves the purpose of providing more precise error messages.

**Options:**

- `REQUIRE_SOURCES`: If no sources are found, a `FATAL_ERROR` message is sent.
- `REQUIRE_PUBLIC_HEADERS` If no public headers are found, a `FATAL_ERROR`
  message is sent.
- `REQUIRE_PRIVATE_HEADERS` If no private headers are found, a `FATAL_ERROR`
  message is sent.

**One Value:**

- `SOURCE_DIR`: This is the directory to search for source files. If it is
  empty, no sources or private headers are collected.
- `INCLUDE_DIR`: This is the directory to search for header files. If it is
  empty, no public headers are collected.
- `OUT_SOURCES`: This is the `PARENT_SCOPED` set variable containing the
  collected source files.
- `OUT_PUBLIC_HEADERS`: This is the `PARENT_SCOPED` set variable containing the
  collected public header files.
- `OUT_PRIVATE_HEADERS`: This is the `PARENT_SCOPED` set variable containing
  the collected private header files, collected from `SOURCE_DIR`.

#### Returned Variables

**Up to** three variables can be returned, depending on how many were specified
at the call site.

- (if `OUT_SOURCES` specified): The identifier given is set to the collected
  sources from `SOURCE_DIR`.
- (if `OUT_PUBLIC_HEADERS` specified): The identifier given is set to the
  collected headers from `INCLUDE_DIR`
- (if `OUT_PRIVATE_HEADERS` specified): The identifier given is set to the
  collected private headers from `SOURCE_DIR`, if any are found.

**Example Usage:**

```cmake
etesca_collect_components(etesca
  REQUIRE_SOURCES
  REQUIRE_PUBLIC_HEADERS
  SOURCE_DIR            "${CMAKE_SOURCE_DIR}/src/etesca"
  INCLUDE_DIR           "${CMAKE_SOURCE_DIR}/include/etesca"
  OUT_SOURCES           globbed_sources
  OUT_PUBLIC_HEADERS    public_headers
  OUT_PRIVATE_HEADERS   private_headers)
```

*Note:* The globs use `CONFIGURE_DEPENDS`, adding a source or header under
`SOURCE_DIR` or `INCLUDE_DIR` causes a reconfigure and is picked up without
editing any CMake file.

### `etesca_configure_library` *(internal)*

Sets the `OUTPUT_NAME`, adds the headers, sources and generated `export.hpp`
to the target, and sets various other
properties/features/definitions, as well as enables static analysis
if globally asked for.

Everything this function does branches on the target's real `TYPE`, so a
`LOCKED_STATIC` library under a `SHARED` `ETESCA_LIBRARY_TYPE` is still named
and defined as a static library, and an interface target is never given a
`PRIVATE` keyword it cannot be given.

#### Parameters

**Positional:**

- `target`: The name of the library target to configure.

**One Value:**

- `BASE_NAME` (required): The library name the target belongs to, without any
  '_static' or '_shared' suffix. It names the file sets, the export header
  directory and the `<BASE_NAME>_STATIC_DEFINE` definition.

**Multi Value:**

- `PUBLIC_HEADERS`: This is the list of headers to add to the target
  (.hpp/.hxx/.hh/.h), found within the root `include/` directory.
- `PRIVATE_HEADERS` (optional): This is the list of headers to add to the
  target (.hpp/.hxx/.hh/.h), found within the root `src/` directory. They are
  skipped for interface targets, which compile nothing.

**Example Usage:**

```cmake
etesca_collect_components(etesca
  REQUIRE_PUBLIC_HEADERS
  REQUIRE_PRIVATE_HEADERS
  SOURCE_DIR            "${CMAKE_SOURCE_DIR}/src/etesca"
  INCLUDE_DIR           "${CMAKE_SOURCE_DIR}/include/etesca"
  OUT_PUBLIC_HEADERS    public_headers
  OUT_PRIVATE_HEADERS   private_headers)

etesca_configure_library(etesca
  BASE_NAME etesca
  PUBLIC_HEADERS ${public_headers}
  PRIVATE_HEADERS ${private_headers})
```

### `etesca_create_library`

Furthest abstracted function this module offers. It leverages all of the
previously defined *(internal)* functions as well as the
`append_global_libraries` function to add the created target to globally
maintained list of libraries.

#### Parameters

**Options:**

*Note:* Up to 1 `LOCKED_*` option may be set at a time.

- `LOCKED_STATIC`: Disregards the set `ETESCA_LIBRARY_TYPE` and builds the
  library as STATIC.
- `LOCKED_SHARED`: Disregards the set `ETESCA_LIBRARY_TYPE` and builds the
  library as SHARED.
- `LOCKED_STATIC_SHARED`: Disregards the set `ETESCA_LIBRARY_TYPE` and builds
  the library as STATIC and SHARED.
- `NO_DEFAULT_LINKS`: Suppresses the automatic `etesca::warnings` and
  `etesca::options` links, for a library that must opt out of them.
- `NO_INSTALL`: Skips the `install()` rules for this library even when
  `ETESCA_INSTALL` is on.

**One Value:**

- `NAME`: This is the name of the library to create, it is **required**.
- `KIND`: One of `COMPILED`, `HEADER_ONLY` or `INTERFACE`. Defaults to `AUTO`,
  which resolves to `COMPILED` when sources were found, `HEADER_ONLY` when
  only public headers were found, and `INTERFACE` when neither were. Setting
  it explicitly turns a mismatch into a `FATAL_ERROR` rather than a silent
  reclassification. `KIND INTERFACE` never searches the directories at all.
- `SOURCE_DIR`: This is the directory containing the source files, if it is not
  provided it is set to the default `"${PROJECT_SOURCE_DIR}/src/${NAME}/"`
  directory.
- `INCLUDE_DIR` This is the directory containing the header files, if it is not
  provided it is set to the default `"${PROJECT_SOURCE_DIR}/include/${NAME}/"`
  directory.

**Multi Value:**

- `SOURCES`: This is a list of full paths of sources to be added to the
  library. Anything found in `SOURCE_DIR` is appended to it.
- `PUBLIC_HEADERS`: This is a list of full paths of public headers to be added
  to the library. Anything found in `INCLUDE_DIR` is appended to it.
- `PRIVATE_HEADERS`: This is a list of full paths of private headers to be
  added to the library. Anything found in `SOURCE_DIR` is appended to it.
- `LINK_PUBLIC`: Libraries to link and propagate to consumers.
- `LINK_PRIVATE`: Libraries to link without propagating to consumers.
- `LINK_INTERFACE`: Libraries to propagate to consumers without linking.

### `get_global_libraries`

Used to retrieve the list of stored library targets from the
`ETESCA_LIBRARY_TARGETS` global variable, appended to via the
`append_global_libraries` function.

#### Parameters

**Positional:**

- `OUTPUT_VAR`: The name of the variable returned to `PARENT_SCOPE` containing
  the list of libraries.

**Example Usage:**

```cmake
get_global_libraries(out_libs)
```

*Note:* The list contains interface targets as well as compiled ones, callers
that only wants linkable artifacts should check each entry's `TYPE`.

### `etesca_link_target`

Applies the default links and any caller supplied links to a single target,
choosing the correct scope keyword from the target's real `TYPE`. It is shared
by `etesca_create_library` and `etesca_create_app` so both behave identically.

Because CMake rejects `PUBLIC` and `PRIVATE` on an interface library, both are
folded to `INTERFACE` for those targets. A `LINK_PRIVATE` dependency on a
header only library is therefore visible to consumers.

#### Parameters

**Positional:**

- `target`: The name of the target to link.

**Options:**

- `NO_DEFAULT_LINKS`: Skips linking `etesca::warnings` and `etesca::options`,
  which are otherwise linked privately.

**Multi Value:**

- `LINK_PUBLIC`: Libraries to link and propagate to consumers.
- `LINK_PRIVATE`: Libraries to link without propagating to consumers.
- `LINK_INTERFACE`: Libraries to propagate to consumers without linking.

**Example Usage:**

```cmake
etesca_link_target(etesca
  LINK_PUBLIC   SQLite::SQLite3
  LINK_PRIVATE  etesca::internal)
```

## Practical Usage

You normally should only be using the `get_global_libraries` and
`etesca_create_library` functions like so:

```cmake
# src/CMakeLists.txt
etesca_create_library(
  NAME etesca)

etesca_create_library(
  NAME etesca_cli
  LOCKED_STATIC
  LINK_PUBLIC etesca::etesca)

# apps/CMakeLists.txt
etesca_create_app(
  NAME etesca
  DEFAULT_DIRS
  LINK_PRIVATE etesca::etesca)
```

```cmake
# tests/CMakeLists.txt
get_global_libraries(etesca_libs)

foreach(etesca_library IN LISTS etesca_libs)
  get_target_property(etesca_library_type ${etesca_library} TYPE)

  if(etesca_library_type STREQUAL "INTERFACE_LIBRARY")
    continue()
  endif()
endforeach()
```

## Notes

*Note:* `etesca_create_app` is defined in `cmake/AppCreator.cmake`, which
depends on `etesca_link_target` from this module, so this module must be
**included first**.
