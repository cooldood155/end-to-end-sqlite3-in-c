add_executable(etesca_app main.cpp)

target_link_libraries(etesca_app PRIVATE
  etesca::etesca
  etesca::warnings
  etesca::options)
set_target_properties(etesca_app PROPERTIES OUTPUT_NAME etesca)

etesca_enable_static_analysis(etesca_app)

if(ETESCA_INSTALL)
  install(TARGETS etesca_app RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
endif()
