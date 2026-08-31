add_executable(etesca_codegen codegen.cpp)
add_executable(etesca::codegen ALIAS etesca_codegen)

target_link_libraries(etesca_codegen PRIVATE etesca)

etesca_enable_static_analysis(eteseca_codegen)

set_target_properties(etesca_codegen PROPERTIES EXPORT_NAME codegen)

export(TARGETS etesca_codegen
  NAMESPACE etesca::
  FILE "${PROJECT_BINARY_DIR}/etescaHostToolsConfig.cmake")
