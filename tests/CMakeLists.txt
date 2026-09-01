find_package(Catch2 3 REQUIRED)
include(Catch)

list(LENGTH ETESCA_LIBRARY_TARGETS etesca_library_count)

foreach(etesca_library IN LISTS ETESCA_LIBRARY_TARGETS)
  if(etesca_library_count GREATER 1)
    string(REPLACE "etesca_" "" etesca_variant "${etesca_library}")
    set(etesca_test_target "etesca_tests_${etesca_variant}")
  else()
    set(etesca_test_target etesca_tests)
  endif()

  add_executable(${etesca_test_target} tests_core.cpp)

  target_link_libraries(${etesca_test_target} PRIVATE
    ${etesca_library}
    etesca::warnings
    etesca::options
    Catch2::Catch2WithMain)

  if(CMAKE_CROSSCOMPILING AND NOT CMAKE_CROSSCOMPILING_EMULATOR)
    add_test(NAME ${etesca_test_target} COMMAND ${etesca_test_target})
    set_tests_properties(${etesca_test_target} PROPERTIES DISABLED TRUE)
  else()
    catch_discover_tests(${etesca_test_target}
      TEST_PREFIX "${etesca_test_target}: "
      PROPERTIES LABELS "unit"
      DISCOVERY_MODE PRE_TEST)

    etesca_add_valgrind_test(${etesca_test_target})
  endif()
endforeach()
