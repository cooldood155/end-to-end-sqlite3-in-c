add_executable(etesca_codegen codegen.cpp)
add_executable(etesca::codegen ALIAS etesca_codegen)

etesca_enable_static_analysis(etesca_codegen)

set_target_properties(etesca_codegen PROPERTIES
  EXPORT_NAME codegen
  RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")

export(TARGETS etesca_codegen
  NAMESPACE etesca::
  FILE "${PROJECT_BINARY_DIR}/etescaHostToolsConfig.cmake")
