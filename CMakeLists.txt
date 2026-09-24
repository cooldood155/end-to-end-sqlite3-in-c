cmake_minimum_required(VERSION 3.30)

list(APPEND CMAKE_MODULE_PATH
  "${CMAKE_CURRENT_LIST_DIR}/cmake/projectkit"
  "${CMAKE_CURRENT_LIST_DIR}/cmake")

include(ConanBuildDir)

pk_require_conan_build_dir(
  OUT_BUILD_TYPE ETESCA_BUILD_TYPE
  OUT_DIR        etesca_conan_dir)

set(CONAN_BUILD_DIR "${etesca_conan_dir}" CACHE INTERNAL
  "Conan's binary output path for the current configuration / build type.")

project(etesca
  VERSION     0.0.0
  DESCRIPTION "C/C++ CLI, written in C, for managing SQLite3 databases (average CRUD actions and possibly extra features)"
  LANGUAGES   C CXX)

include(ProjectKit)

pk_project_setup(CXX_STANDARD 23 C_STANDARD 23)
pk_check_shared_intent()
pk_require_host_tools()

find_package(SQLite3 REQUIRED)

if(NOT CMAKE_CROSSCOMPILING)
  add_subdirectory(tools)
endif()

if(NOT ETESCA_LIBRARY_TYPE STREQUAL "NONE")
  add_subdirectory(src)
endif()

if(ETESCA_BUILD_APPS)
  add_subdirectory(apps)
endif()

if(ETESCA_BUILD_TESTS OR NOT ETESCA_FUZZER STREQUAL "off")
  enable_testing()
endif()

if(ETESCA_BUILD_TESTS)
  add_subdirectory(tests)
endif()

if(ETESCA_INSTALL AND NOT ETESCA_LIBRARY_TYPE STREQUAL "NONE")
  pk_install_package(INTERFACE_TARGETS etesca_warnings etesca_options)
endif()

pk_link_compile_commands()

pk_enable_cpack()
