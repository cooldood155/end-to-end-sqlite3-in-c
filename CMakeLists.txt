cmake_minimum_required(VERSION 3.30)

# End-To-End SQLite3 C API (ETESCA)
project(etesca
  VERSION 0.0.0
  DESCRIPTION "C/C++ CLI, written in C, for managing SQLite3 databases
                  (average CRUD actions and possibly extra features)"
  LANGUAGES   C CXX)

if (PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
  message(FATAL_ERROR
    "In-source builds are not supported, please use a build directory")
endif()

if(NOT CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang|AppleClang|IntelLLVM|MSVC)$")
  message(FATAL_ERROR
    "This project requires a mianstream compiler; found: ${CMAKE_CXX_COMPILER_ID}")
endif()

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

include(GNUInstallDirs)

option(ETESCA_BUILD_APPS   "Build etesca"                  ${PROJECT_IS_TOP_LEVEL})
option(ETESCA_BUILD_TESTS  "Build etesca tests"            ${PROJECT_IS_TOP_LEVEL})
option(ETESCA_INSTALL      "Generate etesca install rules" ${PROJECT_IS_TOP_LEVEL})
option(ETESCA_WERROR       "Treat warnings as errors"      OFF)

set(ETESCA_LIBRARY_TYPE "" CACHE STRING
  "Library artifacts to build: STATIC, SHARED, STATIC+SHARED, NONE, or empty to follow BUILD_SHARED_LIBS")
set_property(CACHE ETESCA_LIBRARY_TYPE PROPERTY STRINGS "" STATIC SHARED "STATIC+SHARED" NONE)

if(NOT ETESCA_LIBRARY_TYPE)
  if(BUILD_SHARED_LIBS)
    set(ETESCA_LIBRARY_TYPE SHARED)
  else()
    set(ETESCA_LIBRARY_TYPE STATIC)
  endif()
  set(ETESCA_LIBRARY_TYPE_FOLLOWS_BUILD_SHARED_LIBS TRUE)
endif()

if(NOT ETESCA_LIBRARY_TYPE MATCHES "^(STATIC|SHARED|STATIC\\+SHARED|NONE)$")
  message(FATAL_ERROR
    "ETESCA_LIBRARY_TYPE must be STATIC, SHARED, STATIC+SHARED or NONE, not '${ETESCA_LIBRARY_TYPE}'")
endif()

# Static Analysis (SA)
option(ETESCA_SA_ALL        "Toggle static analysis tools"      OFF)
option(ETESCA_SA_CPPCHECK   "Toggle Cppcheck static analysis"   OFF)
option(ETESCA_SA_CLANG_TIDY "Toggle Clang-Tidy static analysis" OFF)

set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib")

if(CMAKE_TOOLCHAIN_FILE AND ETESCA_LIBRARY_TYPE_FOLLOWS_BUILD_SHARED_LIBS)
  get_filename_component(ETESCA_GENERATORS_DIR "${CMAKE_TOOLCHAIN_FILE}" DIRECTORY)

  if(EXISTS "${ETESCA_GENERATORS_DIR}/etesca_intent.cmake")
    include("${ETESCA_GENERATORS_DIR}/etesca_intent.cmake")

    if(BUILD_SHARED_LIBS)
      set(ETESCA_CACHED_SHARED ON)
    else()
      set(ETESCA_CACHED_SHARED OFF)
    endif()

    if(NOT ETESCA_CACHED_SHARED STREQUAL ETESCA_TOOLCHAIN_SHARED)
      message(FATAL_ERROR
        "Conan was last run with shared=${ETESCA_TOOLCHAIN_SHARED}, but this build tree is "
        "already configured with BUILD_SHARED_LIBS=${ETESCA_CACHED_SHARED}. CMake never "
        "overwrites a cached BUILD_SHARED_LIBS causing wrong library binaries. "
        "Delete ${PROJECT_BINARY_DIR} and configure again.")
    endif()
  endif()
endif()

include(CompilerWarnings)
include(ProjectOptions)
include(Tools)
include(HostTools)

if(CMAKE_CROSSCOMPILING)
  set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)
  set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
  set(CMAKE_INSTALL_RPATH "$ORIGIN/../${CMAKE_INSTALL_LIBDIR}")

else()
  set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

  if(APPLE)
    set(CMAKE_INSTALL_RPATH "@loader_path/../${CMAKE_INSTALL_LIBDIR}")
  else()
    set(CMAKE_INSTALL_RPATH "$ORIGIN/../${CMAKE_INSTALL_LIBDIR}")
  endif()

  add_subdirectory(tools)
endif()

add_subdirectory(src)
