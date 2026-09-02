cmake_minimum_required(VERSION 3.30)

# End-To-End SQLite3 C API (ETESCA)
project(etesca
  VERSION 0.0.0
  DESCRIPTION "C/C++ CLI, written in C, for managing SQLite3 databases (average CRUD actions and possibly extra features)"
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

set(ETESCA_CXX_STANDARD "23" CACHE STRING "C++ standard the project requires")
set_property(CACHE ETESCA_CXX_STANDARD PROPERTY STRINGS 17 20 23 26)

if(NOT ETESCA_CXX_STANDARD MATCHES "^(17|20|23|26)$")
  message(FATAL_ERROR "ETESCA_CXX_STANDARD must be 17, 20, 23 or 26, not '${ETESCA_CXX_STANDARD}'")
endif()

set(CMAKE_CXX_STANDARD ${ETESCA_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

set(ETESCA_C_STANDARD "23" CACHE STRING "C++ standard the project requires")
set_property(CACHE ETESCA_C_STANDARD PROPERTY STRINGS 17 20 23 26)

if(NOT ETESCA_C_STANDARD MATCHES "^(17|20|23|26)$")
  message(FATAL_ERROR "ETESCA_C_STANDARD must be 17, 20, 23 or 26, not '${ETESCA_C_STANDARD}'")
endif()

set(CMAKE_C_STANDARD ${ETESCA_C_STANDARD})
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
include(StaticAnalysis)
include(Tooling)
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

if(ETESCA_BUILD_APPS)
  add_subdirectory(apps)
endif()

if(ETESCA_BUILD_TESTS OR NOT ETESCA_FUZZER STREQUAL "off")
  enable_testing()
endif()

if(ETESCA_BUILD_TESTS)
  add_subdirectory(tests)
endif()

if(NOT ETESCA_FUZZER STREQUAL "off" AND NOT ETESCA_LIBRARY_TYPE STREQUAL "NONE")
  include(CMakePackageConfigHelpers)

  install(TARGETS etesca_warnings etesca_options EXPORT etescaTargets)
  install(EXPORT etescaTargets
    NAMESPACE   etesca::
    FILE        etescaTargets.cmake
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/etesca")

  configure_package_config_file(
    "${PROJECT_SOURCE_DIR}/cmake/etescaConfig.cmake.in"
    "${PROJECT_BINARY_DIR}/etescaConfig.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/etesca")

  configure_package_config_file(
    "${PROJECT_BINARY_DIR}/etescaConfigVersion.cmake"
    COMPATIBILITY SameMajorVersion)

  install(FILES
    "${PROJECT_BINARY_DIR}etescaConfig.cmake"
    "${PROJECT_BINARY_DIR}/etescaConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/etesca")

  list(GET ETESCA_LIBRARY_TARGETS 0 ETESCA_PC_TARGET)
  get_target_property(ETESCA_PC_LIBRARY_NAME ${ETESCA_PC_TARGET} OUTPUT_NAME)

  if(NOT ETESCA_PC_LIBRARY_NAME)
    set(ETESCA_PC_LIBRARY_NAME "${PROJECT_NAME}")
  endif()

  set(ETESCA_PC_CFLAGS "")

  if(ETESCA_LIBRARY_TYPE STREQUAL "STATIC")
    set(ETESCA_PC_CFLAGS " -DETESCA_STATIC_DEFINE")
  endif()

  set(ETESCA_PC_EXEC_PREFIX "\${prefix}")

  if(IS_ABSOLUTE "${CMAKE_INSTALL_LIBDIR}")
    set(ETESCA_PC_PREFIX "${CMAKE_INSTALL_PREFIX}")
    set(ETESCA_PC_LIBDIR "${CMAKE_INSTALL_LIBDIR}")
  else()
    file(RELATIVE_PATH ETESCA_PC_PREFIX
      "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/pkgconfig"
      "${CMAKE_INSTALL_PREFIX}")
    string(REGEX REPLACE "/+$" "" ETESCA_PC_PREFIX "${ETESCA_PC_PREFIX}")
    set(ETESCA_PC_PREFIX "\${pcfiledir}/${ETESCA_PC_PREFIX}")
    set(ETESCA_PC_LIBDIR "\${prefix}/${CMAKE_INSTALL_LIBDIR}")
  endif()

  if(IS_ABSOLUTE "${CMAKE_INSTALL_INCLUDEDIR}")
    set(ETESCA_PC_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}")
  else()
    set(ETESCA_PC_INCLUDEDIR "\${prefix}/${CMAKE_INSTALL_INCLUDEDIR}")
  endif()

  configure_file(
    "${PROJECT_SOURCE_DIR}/cmake/etesca.pc.in"
    "${PROJECT_BINARY_DIR}/etesca.pc"
    @ONLY)

  install(FILES "${PROJECT_BINARY_DIR}/etesca.pc"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig")
endif()

set(CONAN_GENERATORS_DIR "${CMAKE_BINARY_DIR}/generators")
if(PROJECT_IS_TOP_LEVEL AND CMAKE_EXPORT_COMPILE_COMMANDS AND EXISTS "${CONAN_GENERATORS_DIR}")

  file(CREATE_LINK
    "${CONAN_GENERATORS_DIR}/compile_commands.json"
    "${PROJECT_SOURCE_DIR}/compile_commands.json"
    RESULT ETESCA_COMPILE_COMMANDS_LINK
    COPY_ON_ERROR SYMBOLIC)

  if(NOT ETESCA_COMPILE_COMMANDS_LINK)
    message(FATAL_ERROR
      "Failed to create a symlink from ${CONAN_GENERATORS_DIR}/compile_commands.json "
      "to ${PROJECT_SOURCE_DIR}/compile_commands.json, also failed directy copy")
  endif()
endif()

if(ETESCA_INSTALL AND PROJECT_IS_TOP_LEVEL)
  set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
  set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
  set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
  set(CPACK_PACKAGE_FILE_NAME
    "${PROJECT_NAME}-${PROJECT_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
  set(CPACK_GENERATOR "TGZ;ZIP")
  set(CPACK_VERBATIM_VARIABLES ON)
  set(CPACK_SOURCE_GENERATOR "TGZ")
  set(CPACK_SOURCE_IGNORE_FILES
    "/\\\\.git/"
    "/build/"
    "/stage/"
    "/_install/"
    "/\\\\.conan-cache/"
    "/\\\\.vscode/"
    "/docs/")

  include(CPack)
endif()
