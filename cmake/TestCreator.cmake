function(etesca_create_test)
  set(options
    NO_DEFAULT_LINKS
    NO_VALGRIND)
  set(one_value_args NAME SOURCE_DIR LABEL)
  set(multi_value_args SOURCES LINK_PRIVATE)

  cmake_parse_arguments(ARG
    "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(NOT ARG_NAME)
    message(FATAL_ERROR "etesca_create_test requires a 'NAME' argument.")
  endif()
  if(ARG_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR
      "etesca_create_test (func): unrecognized arguments for '${ARG_NAME}': "
      "${ARG_UNPARSED_ARGUMENTS}")
  endif()
  if(NOT COMMAND catch_discover_tests)
    message(FATAL_ERROR
      "etesca_create_test (func): 'catch_discover_tests' is not defined; call "
      "find_package(Catch2 3 REQUIRED) and include(Catch) first.")
  endif()

  if(NOT ARG_LABEL)
    set(ARG_LABEL "unit")
  endif()
  if(NOT ARG_SOURCE_DIR)
    set(ARG_SOURCE_DIR "${PROJECT_SOURCE_DIR}/tests/${ARG_NAME}")
  endif()

  etesca_collect_components(${ARG_NAME}
    REQUIRE_SOURCES
    SOURCE_DIR "${ARG_SOURCE_DIR}"
    OUT_SOURCES globbed_sources
    OUT_PRIVATE_HEADERS globbed_private_headers)

  list(APPEND ARG_SOURCES ${globbed_sources})

  get_global_libraries(etesca_libs)

  set(library_variants "")
  foreach(etesca_library IN LISTS etesca_libs)
    if(etesca_library MATCHES "^${ARG_NAME}(_static|_shared)?$")
      list(APPEND library_variants ${etesca_library})
    endif()
  endforeach()

  if(NOT library_variants)
    message(FATAL_ERROR
      "etesca_create_test (func): no library targets found for '${ARG_NAME}'. "
      "Was etesca_create_library(NAME ${ARG_NAME} ...) called first?")
  endif()

  if(ARG_NO_DEFAULT_LINKS)
    set(default_links NO_DEFAULT_LINKS)
  else()
    set(default_links "")
  endif()

  foreach(etesca_library IN LISTS library_variants)
    if(etesca_library MATCHES "_static$")
      set(etesca_test_target "${ARG_NAME}_tests_static")
    elseif(etesca_library MATCHES "_shared$")
      set(etesca_test_target "${ARG_NAME}_tests_shared")
    else()
      set(etesca_test_target "${ARG_NAME}_tests")
    endif()

    add_executable(${etesca_test_target} ${ARG_SOURCES})

    if(globbed_private_headers)
      target_sources(${etesca_test_target}
        PRIVATE
          FILE_SET    ${etesca_test_target}_headers
          TYPE        HEADERS
          BASE_DIRS   "${PROJECT_SOURCE_DIR}/tests"
          FILES       ${globbed_private_headers})
    endif()

    target_compile_features(${etesca_test_target} PRIVATE
      cxx_std_${ETESCA_CXX_STANDARD})

    etesca_link_target(${etesca_test_target}
      ${default_links}
      LINK_PRIVATE
        ${etesca_library}
        ${ARG_LINK_PRIVATE}
        Catch2::Catch2WithMain)

    if(CMAKE_CROSSCOMPILING AND NOT CMAKE_CROSSCOMPILING_EMULATOR)
      add_test(NAME ${etesca_test_target} COMMAND ${etesca_test_target})
      set_tests_properties(${etesca_test_target} PROPERTIES DISABLED TRUE)
    else()
      catch_discover_tests(${etesca_test_target}
        TEST_PREFIX "${etesca_test_target}: "
        PROPERTIES LABELS "${ARG_LABEL}"
        DISCOVERY_MODE PRE_TEST)

      if(NOT ARG_NO_VALGRIND)
        etesca_add_valgrind_test(${etesca_test_target})
      endif()
    endif()

    set_property(GLOBAL APPEND PROPERTY ETESCA_TEST_TARGETS ${etesca_test_target})

    message(STATUS
      "etesca: library tests built for '${etesca_library}' with target name "
      "of '${etesca_test_target}'.")
  endforeach()
endfunction()

function(get_global_tests OUTPUT_VAR)
  get_property(temp_list GLOBAL PROPERTY ETESCA_TEST_TARGETS)
  set(${OUTPUT_VAR} "${temp_list}" PARENT_SCOPE)
endfunction()
