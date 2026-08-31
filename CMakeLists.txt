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

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

include(GNUInstallDirs)

option(ETESCA_BUILD        "Build etesca"                  ${PROJECT_IS_TOP_LEVEL})
option(ETESCA_BUILD_TESTS  "Build etesca tests"            ${PROJECT_IS_TOP_LEVEL})
option(ETESCA_INSTALL      "Generate etesca install rules" ${PROJECT_IS_TOP_LEVEL})
option(ETESCA_WERROR       "Treat warnings as errors"         OFF)

# Static Analysis (STA)
option(ETESCA_STA_ALL        "Toggle static analysis tools"      OFF)
option(ETESCA_STA_CPPCHECK   "Toggle Cppcheck static analysis"   OFF)
option(ETESCA_STA_CLANG_TIDY "Toggle Clang-Tidy static analysis" OFF)

set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

include(CompilerWarnings)
include(ProjectOptions)
