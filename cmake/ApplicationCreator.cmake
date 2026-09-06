function(append_global_applications)
  set(multi_value_args TARGETS)
  cmake_parse_arguments(ARG "" "" "${multi_value_args}" ${ARGN})

  if(NOT ARG_TARGETS)
    message(FATAL_ERROR
      "append_global_applications (func): No 'TARGETS' were provided?")
  endif()

  set_property(GLOBAL APPEND PROPERTY ETESCA_APPLICATION_TARGETS ${ARG_TARGETS})
endfunction()

function(get_global_applications OUTPUT_VAR)
  get_property(temp_list GLOBAL PROPERTY ETESCA_APPLICATION_TARGETS)
  set(${OUTPUT_VAR} "${temp_list}" PARENT_SCOPE)
endfunction()

function(etesca_create_app)
  set(options
    DEFAULT_DIRS
    NO_DEFAULT_LINKS
    NO_INSTALL)
  set(one_value_args NAME TARGET_NAME OUTPUT_NAME SOURCE_DIR)
  set(multi_value_args
    SOURCES
    PRIVATE_HEADERS
    LINK_PRIVATE
    LINK_INTERFACE)

  cmake_parse_arguments(ARG
    "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(NOT ARG_NAME)
    message(FATAL_ERROR "etesca_create_app requires a 'NAME' argument.")
  endif()
  if(ARG_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR
      "etesca_create_app (func): unrecognized arguments for '${ARG_NAME}': "
      "${ARG_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT ARG_TARGET_NAME)
    set(ARG_TARGET_NAME "${ARG_NAME}_app")
  endif()
  if(NOT ARG_OUTPUT_NAME)
    set(ARG_OUTPUT_NAME "${ARG_NAME}")
  endif()
  if(NOT ARG_SOURCE_DIR)
    set(ARG_SOURCE_DIR "${PROJECT_SOURCE_DIR}/apps/${ARG_NAME}")
  endif()

  if(ARG_DEFAULT_DIRS)
    etesca_collect_component(${ARG_NAME}
      REQUIRE_SOURCES
      SOURCE_DIR "${ARG_SOURCE_DIR}"
      OUT_SOURCES globbed_sources
      OUT_PRIVATE_HEADERS globbed_private_headers)

    list(APPEND ARG_SOURCES ${globbed_sources})
    list(APPEND ARG_PRIVATE_HEADERS ${globbed_private_headers})
  endif()

  if(NOT ARG_SOURCES)
    message(FATAL_ERROR
      "etesca_create_app (func): No sources found for '${ARG_NAME}': "
      "'DEFAULT_DIRS' not set and 'SOURCES' is empty?")
  endif()

  add_executable(${ARG_TARGET_NAME} ${ARG_SOURCES})

  set_target_properties(${ARG_TARGET_NAME} PROPERTIES
    OUTPUT_NAME "${ARG_OUTPUT_NAME}")

  if(ARG_PRIVATE_HEADERS)
    target_sources(${ARG_TARGET_NAME}
      PRIVATE
        FILE_SET    ${ARG_NAME}_app_private_headers
        TYPE        HEADERS
        BASE_DIRS   "${PROJECT_SOURCE_DIR}/apps"
        FILES       ${ARG_PRIVATE_HEADERS})
  endif()

  target_compile_features(${ARG_TARGET_NAME} PRIVATE
    cxx_std_${ETESCA_CXX_STANDARD})

  target_compile_definitions(${ARG_TARGET_NAME} PRIVATE
    ETESCA_VERSION_STRING="${PROJECT_VERSION}")

  if(ARG_NO_DEFAULT_LINKS)
    set(default_links NO_DEFAULT_LINKS)
  else()
    set(default_links "")
  endif()

  etesca_link_target(${ARG_TARGET_NAME}
    ${default_links}
    LINK_PRIVATE ${ARG_LINK_PRIVATE}
    LINK_INTERFACE ${ARG_LINK_INTERFACE})

  etesca_enable_static_analysis(${ARG_TARGET_NAME})

  set_property(GLOBAL APPEND PROPERTY ETESCA_APP_TARGETS ${ARG_TARGET_NAME})

  if(ETESCA_INSTALL AND NOT ARG_NO_INSTALL)
    install(TARGETS ${ARG_TARGET_NAME}
      RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
  endif()

  append_global_applications(TARGETS "${ARG_TARGET_NAME}")

  message(STATUS "etesca: Application built for '${ARG_NAME}' "
    "with executable target named '${ARG_TARGET_NAME}'.")
endfunction()
