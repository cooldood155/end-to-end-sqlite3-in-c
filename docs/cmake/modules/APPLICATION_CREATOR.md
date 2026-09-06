# `cmake/ApplicationCreator.cmake` Documentation

As the name suggests, this module provides functionality for creating CMake
executables. It is the executable counterpart to
`cmake/LibraryCreator.cmake` and shares **that module's** collection and
linking functions meaning applications follow the same conventions libraries
do.

Application sources live in `apps/<application_name>/` and are collected
recursively, so adding a source file or a private header never requires
editing a CMake file!

## What `ApplicationCreator` Provides

This module provides functions only; **one function** is defined, and it is
intended to be used directly.

### `etesca_create_app`

Creates a single executable target, collects its sources and private headers,
links it, enables static analysis, and installs it when `ETESCA_INSTALL` is
on.

The target name and the binary name are separate **on purpose**. An application
named `etesca` produces the target `etesca_app` so it does not collide with
the `etesca` library target, while the binary it produces is still named
`etesca`.

#### Parameters

**Options:**

*Note:* `DEFAULT_DIRS` is required if no `SOURCES` are provided.

- `DEFAULT_DIRS`: This value appends all found sources and private headers
  from the default `apps/<application_name>/` directory to the `SOURCES` and
  `PRIVATE_HEADERS` variables. Without it the directory is never searched, so
  an application built from an explicit `SOURCES` list does not need one to
  exist.
- `NO_DEFAULT_LINKS`: Suppresses the automatic `etesca::warnings` and
  `etesca::options` links, for an application that **must** opt out of them.
- `NO_INSTALL`: Skips the `install()` rule for this application even when
  `ETESCA_INSTALL` is on, for a development tool, diagnostic tool, etc., that
  should not ship.

**One Value:**

- `NAME`: This is the name of the application to create, it is **required**.
- `TARGET_NAME`: The CMake target to create, if it is not provided it is set
  to the default `"${NAME}_app"`.
- `OUTPUT_NAME`: The name of the produced binary, if it is not provided it is
  set to the default `"${NAME}"`.
- `SOURCE_DIR`: This is the directory containing the source files, if it is
  not provided it is set to the default `"${PROJECT_SOURCE_DIR}/apps/${NAME}/"`
  directory.

**Multi Value:**

- `SOURCES`: This is a list of full paths of sources to be added to the
  application. Anything found in `SOURCE_DIR` is appended to it when
  `DEFAULT_DIRS` is set.
- `PRIVATE_HEADERS`: This is a list of full paths of private headers to be
  added to the application. Anything found in `SOURCE_DIR` is appended to it
  when `DEFAULT_DIRS` is set. They are added as a `FILE_SET` based at
  `apps/`, so a header at `apps/etesca/cli/parse.hpp` is included as
  `"etesca/cli/parse.hpp"`. They are **never installed**.
- `LINK_PRIVATE`: Libraries to link into the application.
- `LINK_INTERFACE`: Libraries to propagate to consumers without linking.
  Rarely useful for an executable, and provided only *for symmetry* with
  `etesca_link_target`.

*Note:* There is no `LINK_PUBLIC`; nothing consumes an executable, so a public
link would be *identical* to a private one in this scenario.

**Example Usage:**

```cmake
etesca_create_app(
  NAME etesca
  DEFAULT_DIRS
  LINK_PRIVATE etesca::etesca)

etesca_create_app(
  NAME etesca_debug_dump
  DEFAULT_DIRS
  NO_INSTALL
  OUTPUT_NAME etesca-debug-dump
  LINK_PRIVATE etesca::etesca)
```

#### Created Targets

One executable is created, named `TARGET_NAME` or `"${NAME}_app"` by default,
producing a binary named `OUTPUT_NAME` or `"${NAME}"` by default.

The created target is appended to the global list of application targets
(`ETESCA_APP_TARGETS`).

#### Errors

- If no `NAME` is given.
- If unrecognized arguments are passed.
- If `DEFAULT_DIRS` is set and no sources are found in `SOURCE_DIR`.
- If neither `DEFAULT_DIRS` nor `SOURCES` produced any sources.

## Practical Usage

You normally should only be using the `etesca_create_app` function like so:

```cmake
# apps/CMakeLists.txt
etesca_create_app(
  NAME etesca
  DEFAULT_DIRS
  LINK_PRIVATE etesca::etesca)
```

The matching layout is:

```plaintext
.
└── apps
    ├── CMakeLists.txt
    ├── etesca
    │   └── main.cpp
    └── cli/
        ├── parse.cpp
        └── parse.hpp
```

## Notes

*Note:* This module depends on `etesca_collect_component` and
`etesca_link_target` from `cmake/LibraryCreator.cmake`, so it must be included
**after it**.
