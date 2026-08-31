set(ETESCA_TOOLING_LABELS "")

option(ETESCA_VALGRIND "Register a Valgrind run of every test executable" OFF)

set(ETESCA_VALGRIND_TOOL "memcheck" CACHE STRING
  "The Valgrind tool valgrind-labelled tests use")
set_property(CACHE ETESCA_VALGRIND_TOOL PROPERTY STRINGS memcheck helgrind drd)

set(ETESCA_FUZZER "off" CACHE STRING
  "Fuzzing engine for fuzz/ targets: off, libfuzzer of afl")
set_property(CACHE ETESCA_FUZZER PROPERTY STRINGS off libfuzzer afl)

set(ETESCA_FUZZ_SECONDS "45" CACHE STRING
  "How long each fuzz target runs when driven by ctest")

if(NOT ETESCA_VALGRIND_TOOL MATCHES "^(memcheck|helgrind|drd)$")
  message(FATAL_ERROR
    "ETESCA_VALGRIND_TOOL must be memcheck, helgrind or drd, NOT
    '${ETESCA_VALGRIND_TOOL}`")
endif()

if(NOT ETESCA_FUZZER MATCHES "^(off|libfuzzer|afl)$")
  message(FATAL_ERROR
    "ETESCA_FUZZER must be off, libfuzzer of afl, NOT '${ETESCA_FUZZER}'")
endif()

# Valgrind (Linux/ELF Only)
if(ETESCA_VALGRIND)
  if(CMAKE_CROSSCOMPILING)
    message(FATAL_ERROR
      "ETESCA_VALGRIND cannot run target binaries from a cross build")
  endif()

  if(compiler_is_msvc OR WIN32)
    message(FATAL_ERROR
      "Valgrind is not supported on Windows/MSVC environments")
  endif()

  find_program(ETESCA_VALGRIND_PATH NAMES valgrind REQUIRED)

  if(ETESCA_VALGRIND_TOOL STREQUAL "memcheck")
    list(APPEND ETESCA_VALGRIND_COMMAND
      "--leak-check=full"
      "--errors-for-leak-kinds=definite,possible"
      "--track-origins=yes")
  endif()

  if(EXISTS "${PROJECT_SOURCE_DIR}/tests/valgrind.supp")
    list(APPEND ETESCA_VALGRIND_COMMAND
      "--suppressions=${PROJECT_SOURCE_DIR}/tests/valgrind.supp")
  endif()

  list(APPEND ETESCA_TOOLING_LABELS valgrind)
  message(STATUS
    "etesca: Valgrind ${ETESCA_VALGRIND_TOOL} tets enabled (${ETESCA_VALGRIND_PATH})")
endif()

function(etesca_add_valgrind_test target)
  if(NOT ETESCA_VALGRIND)
    return()
  endif()

  add_test(NAME "${target}: valgrind"
    COMMAND ${ETESCA_VALGRIND_COMMAND} "$<TARGET_FILE:${target}>")

  set_tests_properties("${target}: valgrind" PROPERTIES
    LABELS "valgrind"
    TIMEOUT 900)
endfunction()

if(NOT ETESCA_FUZZER STREQUAL "off")
  if(CMAKE_CROSSCOMPILING)
    message(FATAL_ERROR
      "ETESCA_FUZZER cannot run target binaries from a cross build")
  endif()

  add_library(etesca_fuzzing INTERFACE)
  add_library(etesca::fuzzing ALIAS etesca_fuzzing)

  if(ETESCA_FUZZER STREQUAL "libfuzzer")
    include(CheckCXXSourceCompiles)

    if(compiler_is_msvc)
      set(fuzz_flag "/fsanitize=fuzzer")
      set(fuzz_no_link_flag "/fsanitize=fuzzer-no-link")
    else()
      set(fuzz_flag "-fsanitize=fuzzer")
      set(fuzz_no_link_flag "-fsanitize=fuzzer-no-link")
    endif()

    set(CMAKE_REQUIRED_FLAGS "${fuzz_flag}")
    set(CMAKE_REQUIRED_LINK_OPTIONS "${fuzz_flag}")
    check_cxx_source_compiles(
      "#include <cstddef>\n#include <cstdint>\nextern \"C\" int LLVMFuzzerTestOneInput(const uint8_t*, size_t) { return 0; }\n"
      ETESCA_HAS_LIBFUZZER)
    unset(CMAKE_REQUIRED_FLAGS)
    unset(CMAKE_REQUIRED_LINK_OPTIONS)

    if(NOT ETESCA_HAS_LIBFUZZER)
      message(FATAL_ERROR
        "The current compiler (${CMAKE_CXX_COMPILER_ID}) cannot link "
        "libFuzzer. Runtime libraries might be missing")
    endif()

    target_compile_options(etesca_fuzzing INTERFACE
      "$<IF:$<BOOL:${compiler_is_msvc}>,${fuzz_flag},${fuzz_no_link_flag}>")
    target_link_options(etesca_fuzzing INTERFACE "${fuzz_flag}")

  else() # AFL Fuzzer
    if(compiler_is_msvc)
      message(FATAL_ERROR
        "AFL++ is unsupported natively on Windows/MSVC")
    endif()

    get_filenam_component(compiler_name "${CMAKE_CXX_COMPILER}" NAME)
    if(NOT compiler_name MATCHES "^afl-")
      message(FATAL_ERROR
        "ETESCA_FUZZER=afl needs and AFL++ compiler wrapper. Configure with "
        "CXX=afl-clang-fast++ or CXX=afl-g++-fast")
    endif()
  endif()

  list(APPEND ETESCA_TOOLING_LABELS fuzz)
  message(STATUS "etesca: fuzzing enabled (${ETESCA_FUZZER})")
endif()

if(ETESCA_TOOLING_LABELS)
  list(JOIN ETESCA_TOOLING_LABELS ", " etesca_tooling_summary)
  message(STATUS "etesca: extra ctest labels: ${etesca_tooling_summary}")
endif()
