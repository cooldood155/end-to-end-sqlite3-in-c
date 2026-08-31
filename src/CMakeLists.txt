include(GenerateExportHeader)

function(etesca_configure_library target)
  if("${target}" STREQUAL "NONE")
    message(STATUS
      "etesca: no library is being configured/built for ${target}")
    return()
  endif()

  target_sources(${target}
    PUBLIC
      FILE_SET    etesca_headers
      TYPE        HEADERS
      BASE_DIRS   "${PROJECT_SOURCE_DIR}/include"
      FILES       "${PROJECT_SOURCE_DIR}/include/etesca/core.hpp"

    PRIVATE
      FILE_SET    etesca_private_headers
      TYPE        HEADERS
      BASE_DIRS   "${CMAKE_CURRENT_SOURCE_DIR}")

  target_sources(${target}
    PUBLIC
      FILE_SET    etesca_generated_headers
      TYPE        HEADERS
      BASE_DIRS   "${PROJECT_BINARY_DIR}/generated"
      FILES       "${PROJECT_BINARY_DIR}/generated/etesca/export.hpp")

  target_compile_features(${target} PUBLIC cxx_std_${ETESCA_CXX_STANDARD})
  target_compile_definitions(${target} PRIVATE ETESCA_VERSION_STRING="${PROJECT_VERSION}")
  target_link_libraries(${target} PRIVATE etesca_warnings etesca_options)

  etesca_enable_static_analysis(${target})

  set_target_properties(${target} PROPERTIES
    OUTPUT_NAME etesca
    VERSION "${PROJECT_VERSION}"
    SOVERSION "${PROJECT_VERSION_MAJOR}"
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON)

  get_target_property(target_type ${target} TYPE)

  if(NOT target_type STREQUAL "SHARED_LIBRARY")
    target_compile_definitions(${target} PUBLIC ETESCA_STATIC_DEFINE)
  endif()
endfunction()

set(ETESCA_LIBRARY_TARGETS "")

if(ETESCA_LIBRARY_TYPE STREQUAL "STATIC+SHARED")
  add_library(etesca_static STATIC core.cpp)
  add_library(etesca_shared SHARED core.cpp)
  set_target_properties(etesca_static PROPERTIES EXPORT_NAME static)
  set_target_properties(etesca_shared PROPERTIES EXPORT_NAME shared DEFINE_SYMBOL etesca_EXPORTS)
  add_library(etesca::static ALIAS etesca_static)
  add_library(etesca::shared ALIAS etesca_shared)
  add_library(etesca::etesca ALIAS etesca_shared)
  list(APPEND ETESCA_LIBRARY_TARGETS etesca_static etesca_shared)
  set(ETESCA_EXPORT_HEADER_TARGET etesca_shared)

elseif(ETESCA_LIBRARY_TYPE STREQUAL "SHARED"
       OR ETESCA_LIBRARY_TYPE_FOLLOWS_BUILD_SHARED_LIBS)
  add_library(etesca SHARED core.cpp)
  add_library(etesca::etesca ALIAS etesca)
  list(APPEND ETESCA_LIBRARY_TARGETS etesca)
  set(ETESCA_EXPORT_HEADER_TARGET etesca)

elseif(ETESCA_LIBRARY_TYPE STREQUAL "STATIC")
  add_library(etesca STATIC core.cpp)
  add_library(etesca::etesca ALIAS etesca)
  list(APPEND ETESCA_LIBRARY_TARGETS etesca)
  set(ETESCA_EXPORT_HEADER_TARGET etesca)
else()
  list(APPEND ETESCA_LIBRARY_TARGETS NONE)
endif()

if(NOT "${ETESCA_LIBRARY_TARGETS}" STREQUAL "NONE")
  generate_export_header(${ETESCA_EXPORT_HEADER_TARGET}
    BASE_NAME etesca
    EXPORT_FILE_NAME "${PROJECT_BINARY_DIR}/generated/etesca/export.hpp")
endif()

foreach(etesca_target IN LISTS ETESCA_LIBRARY_TARGETS)
  etesca_configure_library(${etesca_target})
endforeach()

if(NOT "${ETESCA_LIBRARY_TARGETS}" STREQUAL "NONE")
  etesca_add_generated_source(
    SPEC    "${CMAKE_CURRENT_SOURCE_DIR}/tables.spec"
    OUTPUT  tables.cpp
    TARGETS ${ETESCA_LIBRARY_TARGETS})

  set(ETESCA_LIBRARY_TARGETS ${ETESCA_LIBRARY_TARGETS} PARENT_SCOPE)

  if(ETESCA_INSTALL)
    install(TARGETS ${ETESCA_LIBRARY_TARGETS}
      EXPORT  etescaTargets
      RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
      LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      FILE_SET etesca_headers DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
      FILE_SET etesca_generated_headers DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
  endif()
endif()
