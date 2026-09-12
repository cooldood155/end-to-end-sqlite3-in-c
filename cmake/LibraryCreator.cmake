include(GenerateExportHeader)

function(append_global_libraries)
  set(multi_value_args TARGETS)
  cmake_parse_arguments(ARG "" "" "${multi_value_args}" ${ARGN})

  if(NOT ARG_TARGETS)
    message(FATAL_ERROR
      "append_global_libraries (func): No 'TARGETS' were provided?")
  endif()

  set_property(GLOBAL APPEND PROPERTY ETESCA_LIBRARY_TARGETS ${ARG_TARGETS})
endfunction()

function(get_global_libraries OUTPUT_VAR)
  get_property(temp_list GLOBAL PROPERTY ETESCA_LIBRARY_TARGETS)
  set(${OUTPUT_VAR} "${temp_list}" PARENT_SCOPE)
endfunction()

function(etesca_link_target target)
  set(options NO_DEFAULT_LINKS)
  set(multi_value_args LINK_PUBLIC LINK_PRIVATE LINK_INTERFACE)
  cmake_parse_arguments(ARG
    "${options}" "" "${multi_value_args}" ${ARGN})

  get_target_property(target_type ${target} TYPE)

  if(target_type STREQUAL "INTERFACE_LIBRARY")
    set(pub INTERFACE)
    set(priv INTERFACE)
  else()
    set(pub PUBLIC)
    set(priv PRIVATE)
  endif()

  if(NOT ARG_NO_DEFAULT_LINKS)
    target_link_libraries(${target} ${priv}
      etesca::warnings
      etesca::options)
  endif()

  if(ARG_LINK_PUBLIC)
    target_link_libraries(${target} ${pub} ${ARG_LINK_PUBLIC})
  endif()
  if(ARG_LINK_PRIVATE)
    target_link_libraries(${target} ${priv} ${ARG_LINK_PRIVATE})
  endif()
  if(ARG_LINK_INTERFACE)
    target_link_libraries(${target} INTERFACE ${ARG_LINK_INTERFACE})
  endif()
endfunction()

function(etesca_collect_components NAME)
  set(options
    REQUIRE_SOURCES
    REQUIRE_PUBLIC_HEADERS
    REQUIRE_PRIVATE_HEADERS)
  set(one_value_args
    SOURCE_DIR
    INCLUDE_DIR
    OUT_SOURCES
    OUT_PUBLIC_HEADERS
    OUT_PRIVATE_HEADERS)

  cmake_parse_arguments(ARG
    "${options}" "${one_value_args}" "" ${ARGN})

  set(sources "")
  set(private_headers "")
  set(public_headers "")

  if(ARG_SOURCE_DIR)
    file(GLOB_RECURSE sources CONFIGURE_DEPENDS
      "${ARG_SOURCE_DIR}/*.cpp" "${ARG_SOURCE_DIR}/*.cxx"
      "${ARG_SOURCE_DIR}/*.cc" "${ARG_SOURCE_DIR}/*.c")
    file(GLOB_RECURSE private_headers CONFIGURE_DEPENDS
      "${ARG_SOURCE_DIR}/*.hpp" "${ARG_SOURCE_DIR}/*.hxx"
      "${ARG_SOURCE_DIR}/*.hh" "${ARG_SOURCE_DIR}/*.h")
  endif()

  if(ARG_INCLUDE_DIR)
    file(GLOB_RECURSE public_headers CONFIGURE_DEPENDS
      "${ARG_INCLUDE_DIR}/*.hpp" "${ARG_INCLUDE_DIR}/*.hxx"
      "${ARG_INCLUDE_DIR}/*.hh" "${ARG_INCLUDE_DIR}/*.h")
  endif()

  if(NOT sources AND ARG_REQUIRE_SOURCES)
    message(FATAL_ERROR
      "etesca_collect_components (func): no sources found for '${NAME}' in "
      "'${ARG_SOURCE_DIR}'. Expected files following the format "
      "'*.<cpp|cxx|cc|c>'.")
  endif()
  if(NOT public_headers AND ARG_REQUIRE_PUBLIC_HEADERS)
    message(FATAL_ERROR
      "etesca_collect_components (func): no public headers found for '${NAME}' "
      "in '${ARG_INCLUDE_DIR}'. Expected files following the format "
      "'*.<hpp|hxx|hh|h>'.")
  endif()
  if(NOT private_headers AND ARG_REQUIRE_PRIVATE_HEADERS)
    message(FATAL_ERROR
      "etesca_collect_components (func): no private headers found for "
      "'${NAME}' in '${ARG_SOURCE_DIR}'. Expected files following the format "
      "'*.<hpp|hxx|hh|h>'.")
  endif()

  if(ARG_OUT_SOURCES)
    set(${ARG_OUT_SOURCES} "${sources}" PARENT_SCOPE)
  endif()
  if(ARG_OUT_PUBLIC_HEADERS)
    set(${ARG_OUT_PUBLIC_HEADERS} "${public_headers}" PARENT_SCOPE)
  endif()
  if(ARG_OUT_PRIVATE_HEADERS)
    set(${ARG_OUT_PRIVATE_HEADERS} "${private_headers}" PARENT_SCOPE)
  endif()
endfunction()

function(etesca_add_library NAME)
  if(NOT NAME)
    message(FATAL_ERROR
      "etesca_add_library (func): No NAME was provided?")
  endif()

  set(one_value_args KIND LINKAGE)
  set(multi_value_args SOURCES)
  cmake_parse_arguments(ARG
    "" "${one_value_args}" "${multi_value_args}" ${ARGN})

  string(TOUPPER "${NAME}" NAME_UPPER)

  set(local_library_targets "")
  set(local_export_target "")

  if(ARG_KIND STREQUAL "COMPILED")
    if(NOT ARG_SOURCES)
      message(FATAL_ERROR
        "etesca_add_library (func): No SOURCES were provided?")
    endif()

    if(ARG_LINKAGE STREQUAL "STATIC+SHARED")
      add_library("${NAME}_static" STATIC ${ARG_SOURCES})
      add_library("${NAME}_shared" SHARED ${ARG_SOURCES})

      set_target_properties("${NAME}_static" PROPERTIES EXPORT_NAME static)
      set_target_properties("${NAME}_shared" PROPERTIES EXPORT_NAME shared
                                             DEFINE_SYMBOL "${NAME}_EXPORTS")

      add_library("${NAME}::static" ALIAS "${NAME}_static")
      add_library("${NAME}::shared" ALIAS "${NAME}_shared")
      add_library("${NAME}::${NAME}" ALIAS "${NAME}_shared")

      list(APPEND local_library_targets "${NAME}_static" "${NAME}_shared")
      set(local_export_target "${NAME}_shared")

    elseif(ARG_LINKAGE STREQUAL "SHARED" OR ARG_LINKAGE STREQUAL "STATIC")
      add_library("${NAME}" ${ARG_LINKAGE} ${ARG_SOURCES})
      add_library("${NAME}::${NAME}" ALIAS "${NAME}")

      list(APPEND local_library_targets "${NAME}")
      set(local_export_target "${NAME}")

    else()
      message(FATAL_ERROR
        "etesca_add_library (func): 'LINKAGE' is unrecognized for '${NAME}': "
        "${ARG_LINKAGE}")
    endif()

  elseif(ARG_KIND STREQUAL "HEADER_ONLY" OR ARG_KIND STREQUAL "INTERFACE")
    add_library("${NAME}" INTERFACE)
    add_library("${NAME}::${NAME}" ALIAS "${NAME}")

    list(APPEND local_library_targets "${NAME}")

  else()
    message(FATAL_ERROR
      "etesca_add_library (func): 'KIND' is unrecognized for '${NAME}': "
      "${ARG_KIND}")
  endif()

  set(${NAME_UPPER}_LIBRARY_TARGETS "${local_library_targets}" PARENT_SCOPE)
  set(${NAME_UPPER}_EXPORT_HEADER_TARGET "${local_export_target}" PARENT_SCOPE)
endfunction()

function(etesca_configure_library target)
  set(one_value_args BASE_NAME)
  set(multi_value_args PUBLIC_HEADERS PRIVATE_HEADERS)
  cmake_parse_arguments(ARG
    "" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(NOT TARGET ${target})
    message(FATAL_ERROR
      "etesca_configure_library (func): '${target}' is not a target.")
  endif()
  if(NOT ARG_BASE_NAME)
    message(FATAL_ERROR
      "etesca_configure_library (func): no 'BASE_NAME' given for '${target}'.")
  endif()

  set(BASE_NAME "${ARG_BASE_NAME}")
  string(TOUPPER "${BASE_NAME}" BASE_NAME_UPPER)

  get_target_property(target_type ${target} TYPE)

  if(target_type STREQUAL "INTERFACE_LIBRARY")
    set(pub INTERFACE)
  else()
    set(pub PUBLIC)
  endif()

  if(target MATCHES "_static$")
    set_target_properties(${target} PROPERTIES
      OUTPUT_NAME "${BASE_NAME}-static")
  elseif(target MATCHES "_shared$")
    set_target_properties(${target} PROPERTIES
      OUTPUT_NAME "${BASE_NAME}-shared")
  endif()

  if(ARG_PUBLIC_HEADERS)
    target_sources(${target}
      ${pub}
        FILE_SET    ${BASE_NAME}_headers
        TYPE        HEADERS
        BASE_DIRS   "${PROJECT_SOURCE_DIR}/include"
        FILES       ${ARG_PUBLIC_HEADERS})
  endif()

  if(ARG_PRIVATE_HEADERS AND NOT target_type STREQUAL "INTERFACE_LIBRARY")
    target_sources(${target}
      PRIVATE
        FILE_SET    ${BASE_NAME}_private_headers
        TYPE        HEADERS
        BASE_DIRS   "${PROJECT_SOURCE_DIR}/src"
        FILES       ${ARG_PRIVATE_HEADERS})
  endif()

  if(EXISTS "${PROJECT_BINARY_DIR}/generated/${BASE_NAME}/export.hpp")
    target_sources(${target}
      ${pub}
        FILE_SET    ${BASE_NAME}_generated_headers
        TYPE        HEADERS
        BASE_DIRS   "${PROJECT_BINARY_DIR}/generated"
        FILES       "${PROJECT_BINARY_DIR}/generated/${BASE_NAME}/export.hpp")
  endif()

  target_compile_features(${target} ${pub}
    cxx_std_${ETESCA_CXX_STANDARD})

  if(NOT target_type STREQUAL "INTERFACE_LIBRARY")
    target_compile_definitions(${target} PRIVATE
      ETESCA_VERSION_STRING="${PROJECT_VERSION}")

    etesca_enable_static_analysis(${target})

    set_target_properties(${target} PROPERTIES
      VERSION "${PROJECT_VERSION}"
      SOVERSION "${PROJECT_VERSION_MAJOR}"
      CXX_VISIBILITY_PRESET hidden
      VISIBILITY_INLINES_HIDDEN ON)

    if(NOT target_type STREQUAL "SHARED_LIBRARY")
      target_compile_definitions(${target} PUBLIC
        ${BASE_NAME_UPPER}_STATIC_DEFINE)
    endif()
  endif()
endfunction()

function(etesca_create_library)
  set(options
    LOCKED_STATIC
    LOCKED_SHARED
    LOCKED_STATIC_SHARED
    NO_DEFAULT_LINKS
    NO_INSTALL)
  set(one_value_args NAME KIND SOURCE_DIR INCLUDE_DIR)
  set(multi_value_args
    SOURCES
    PUBLIC_HEADERS
    PRIVATE_HEADERS
    LINK_PUBLIC
    LINK_PRIVATE
    LINK_INTERFACE)

  cmake_parse_arguments(ARG
    "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(NOT ARG_NAME)
    message(FATAL_ERROR "etesca_create_library requires a 'NAME' argument.")
  endif()
  if(ARG_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR
      "etesca_create_library (func): unrecognized arguments for "
      "'${ARG_NAME}': ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT ARG_KIND)
    set(ARG_KIND "AUTO")
  endif()

  set(flags_selected 0)
  set(linkage "")
  if(ARG_LOCKED_STATIC)
    math(EXPR flags_selected "${flags_selected} + 1")
    set(linkage "STATIC")
  endif()
  if(ARG_LOCKED_SHARED)
    math(EXPR flags_selected "${flags_selected} + 1")
    set(linkage "SHARED")
  endif()
  if(ARG_LOCKED_STATIC_SHARED)
    math(EXPR flags_selected "${flags_selected} + 1")
    set(linkage "STATIC+SHARED")
  endif()

  if(flags_selected GREATER 1)
    message(FATAL_ERROR
      "etesca_create_library (func): Only one option flag allowed at once.")
  elseif(flags_selected EQUAL 1)
    message(STATUS
      "etesca: library '${ARG_NAME}' linkage locked to ${linkage}")
  else()
    set(linkage "${ETESCA_LIBRARY_TYPE}")
  endif()

  if(NOT ARG_SOURCE_DIR)
    set(ARG_SOURCE_DIR "${PROJECT_SOURCE_DIR}/src/${ARG_NAME}")
  endif()
  if(NOT ARG_INCLUDE_DIR)
    set(ARG_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/include/${ARG_NAME}")
  endif()

  if(ARG_KIND STREQUAL "INTERFACE")
    set(ARG_SOURCE_DIR "")
    set(ARG_INCLUDE_DIR "")
  endif()

  etesca_collect_components(${ARG_NAME}
    SOURCE_DIR "${ARG_SOURCE_DIR}"
    INCLUDE_DIR "${ARG_INCLUDE_DIR}"
    OUT_SOURCES globbed_sources
    OUT_PUBLIC_HEADERS globbed_public_headers
    OUT_PRIVATE_HEADERS globbed_private_headers)

  list(APPEND ARG_SOURCES ${globbed_sources})
  list(APPEND ARG_PUBLIC_HEADERS ${globbed_public_headers})
  list(APPEND ARG_PRIVATE_HEADERS ${globbed_private_headers})

  if(ARG_KIND STREQUAL "AUTO")
    if(ARG_SOURCES)
      set(ARG_KIND "COMPILED")
    elseif(ARG_PUBLIC_HEADERS)
      set(ARG_KIND "HEADER_ONLY")
    else()
      set(ARG_KIND "INTERFACE")
    endif()
    message(STATUS "etesca: library '${ARG_NAME}' detected as ${ARG_KIND}")
  endif()

  if(ARG_KIND STREQUAL "COMPILED" AND NOT ARG_SOURCES)
    message(FATAL_ERROR
      "etesca_create_library (func): '${ARG_NAME}' is 'KIND' COMPILED but no "
      "sources were found in '${ARG_SOURCE_DIR}' and none were given via "
      "'SOURCES'.")
  endif()
  if(ARG_KIND STREQUAL "HEADER_ONLY" AND NOT ARG_PUBLIC_HEADERS)
    message(FATAL_ERROR
      "etesca_create_library (func): '${ARG_NAME}' is 'KIND' HEADER_ONLY but "
      "no public headers were found in '${ARG_INCLUDE_DIR}'.")
  endif()

  etesca_add_library(${ARG_NAME}
    KIND "${ARG_KIND}"
    LINKAGE "${linkage}"
    SOURCES ${ARG_SOURCES})

  string(TOUPPER "${ARG_NAME}" ARG_NAME_UPPER)
  set(target_list_var "${ARG_NAME_UPPER}_LIBRARY_TARGETS")
  set(export_target_var "${ARG_NAME_UPPER}_EXPORT_HEADER_TARGET")

  if(NOT ${target_list_var})
    message(FATAL_ERROR
      "'${target_list_var}' was not set (internal logic issue).")
  endif()

  if(${export_target_var})
    generate_export_header(${${export_target_var}}
      BASE_NAME        "${ARG_NAME}"
      EXPORT_FILE_NAME "${PROJECT_BINARY_DIR}/generated/${ARG_NAME}/export.hpp")
  endif()

  if(ARG_NO_DEFAULT_LINKS)
    set(default_links NO_DEFAULT_LINKS)
  else()
    set(default_links "")
  endif()

  foreach(lib_target IN LISTS ${target_list_var})
    etesca_configure_library(${lib_target}
      BASE_NAME "${ARG_NAME}"
      PUBLIC_HEADERS ${ARG_PUBLIC_HEADERS}
      PRIVATE_HEADERS ${ARG_PRIVATE_HEADERS})

    etesca_link_target(${lib_target}
      ${default_links}
      LINK_PUBLIC ${ARG_LINK_PUBLIC}
      LINK_PRIVATE ${ARG_LINK_PRIVATE}
      LINK_INTERFACE ${ARG_LINK_INTERFACE})
  endforeach()

  append_global_libraries(TARGETS ${${target_list_var}})

  if(ETESCA_INSTALL AND NOT ARG_NO_INSTALL)
    set(install_file_sets "")
    if(ARG_PUBLIC_HEADERS)
      list(APPEND install_file_sets
        FILE_SET ${ARG_NAME}_headers
          DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
    endif()
    if(${export_target_var})
      list(APPEND install_file_sets
        FILE_SET ${ARG_NAME}_generated_headers
          DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
    endif()

    install(TARGETS ${${target_list_var}}
      EXPORT  ${ARG_NAME}Targets
      RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
      LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      ${install_file_sets})
  endif()
endfunction()
