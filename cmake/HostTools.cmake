if(CMAKE_CROSSCOMPILING)
  find_package(etescaHostTools REQUIRED) # `tools/CMakeLists.txt` exports
else()
  set(etescaHostTools_FOUND TRUE)
endif()

function(etesca_add_generated_source)
  set(singleValueArgs SPEC OUTPUT)
  set(multiValueArgs TARGETS)
  cmake_parse_arguments(arg_etesca_add_generated_source
    "" "${singleValueArgs}" "${multiValueArgs}" ${ARGN})

  set(out "${CMAKE_CURRENT_BINARY_DIR}/${arg_etesca_add_generated_source_OUTPUT}")

  add_custom_command(
    OUTPUT "${out}"
    COMMAND etesca::codegen --input "${arg_etesca_add_generated_source_SPEC}" --output "${out}"
    DEPENDS "${arg_etesca_add_generated_source_SPEC}" etesca::codegen
    COMMENT "Generating ${arg_etesca_add_generated_source_OUTPUT}"
    VERBATIM)

  set_source_files_properties("${out}" PROPERTIES SKIP_LINTING ON)

  foreach(target IN LISTS arg_etesca_add_generated_source_TARGETS)
    target_sources(${target} PRIVATE "${out}")
  endforeach()
endfunction()
