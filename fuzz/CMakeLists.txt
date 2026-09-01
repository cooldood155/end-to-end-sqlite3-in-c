add_executable(etesca_fuzz_core fuzz_core.cpp)

target_link_libraries(etesca_fuzz_core PRIVATE
  etesca::etesca
  etesca::warnings
  etesca::options
  etesca::fuzzing)

etesca_enable_static_analysis(etesca_fuzz_core)
set_target_properties(etesca_fuzz_core PROPERTIES OUTPUT_NAME etesca_fuzz_core)

file(MAKE_DIRECTORY "${PROJECT_BINARY_DIR}/fuzz-corpus/core")

if(ETESCA_FUZZER STREQUAL "libfuzzer")
  add_test(NAME "etesca_fuzz_core: smoke"
    COMMAND etesca_fuzz_core
            "${PROJECT_BINARY_DIR}/fuzz-corpus/core"
            "${CMAKE_CURRENT_SOURCE_DIR}/corpus/core"
            -max_total_time=${ETESCA_FUZZ_SECONDS}
            -print_final_stats=1)

  set_tests_properties("etesca_fuzz_core: smoke" PROPERTIES
    LABELS "fuzz"
    TIMEOUT 1800)
endif()
