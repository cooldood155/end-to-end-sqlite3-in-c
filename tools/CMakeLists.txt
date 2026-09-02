add_executable(etesca_codegen codegen.cpp)
add_executable(etesca::codegen ALIAS etesca_codegen)

etesca_enable_static_analysis(eteseca_codegen)

set_target_properties(etesca_codegen PROPERTIES EXPORT_NAME codegen)

export(TARGETS etesca_codegen
  NAMESPACE etesca::
  FILE "${PROJECT_BINARY_DIR}/etescaHostToolsConfig.cmake")
