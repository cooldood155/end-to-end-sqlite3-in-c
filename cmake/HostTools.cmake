if(CMAKE_CROSSCOMPILING)
  find_package(etescaHostTools REQUIRED)
else()
  set(etescaHostTools_FOUND TRUE)
endif()

function(etesca_add_generated_source)
  set(one_value_args NAME SPEC OUTPUT)
  set(multi_value_args TARGETS)
  cmake_parse_arguments(ARG
    "" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(NOT ARG_NAME)
    message(FATAL_ERROR
      "etesca_add_generated_source (func): No 'NAME' was provided?")
  endif()
  if(NOT ARG_SPEC)
    message(FATAL_ERROR
      "etesca_add_generated_source (func): No 'SPEC' was provided?")
  endif()
  if(NOT ARG_OUTPUT)
    message(FATAL_ERROR
      "etesca_add_generated_source (func): No 'OUTPUT' was provided?")
  endif()
  if(NOT ARG_TARGETS)
    message(FATAL_ERROR
      "etesca_add_generated_source (func): No 'TARGETS' were provided?")
  endif()
  if(NOT EXISTS "${ARG_SPEC}")
    message(FATAL_ERROR
      "etesca_add_generated_source (func): spec '${ARG_SPEC}' does not exist.")
  endif()
  if(NOT TARGET etesca::codegen)
    message(FATAL_ERROR
      "etesca_add_generated_source (func): 'etesca::codegen' is not defined. "
      "When cross compiling, configure a native build first and point "
      "etescaHostTools_DIR at its binary directory.")
  endif()

  set(out "${PROJECT_BINARY_DIR}/generated/${ARG_NAME}/${ARG_OUTPUT}")

  add_custom_command(
    OUTPUT "${out}"
    COMMAND etesca::codegen --input "${ARG_SPEC}" --output "${out}"
    DEPENDS "${ARG_SPEC}" etesca::codegen
    COMMENT "Generating ${ARG_NAME}/${ARG_OUTPUT}"
    VERBATIM)

  set_source_files_properties("${out}" PROPERTIES
    SKIP_LINTING ON
    GENERATED ON)

  foreach(target IN LISTS ARG_TARGETS)
    get_target_property(target_type ${target} TYPE)
    if(target_type STREQUAL "INTERFACE_LIBRARY")
      message(FATAL_ERROR
        "etesca_add_generated_source (func): '${target}' is an interface "
        "library and cannot compile a generated source.")
    endif()

    target_sources(${target} PRIVATE "${out}")
  endforeach()
endfunction()
