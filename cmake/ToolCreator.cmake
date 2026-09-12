function(etesca_create_tool)
  set(options
    VERBATIM)
  set(one_value_args
    NAME
    ALIAS
    ROUT_DIR
    EXPORT_NAME
    EXPORT_NAMESPACE
    EXPORT_FILE
    SOURCE_DIR)
  set(multi_value_args SOURCES NAME_SEPARATORS)

  cmake_parse_arguments(ARG
    "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(NOT ARG_NAME)
    message(FATAL_ERROR
      "'etesca_create_tool' (func): Expects a single-valued NAME argument to "
      "represent the executable target.")
  endif()

  if(NOT ARG_NAME_SEPARATORS)
    set(ARG_NAME_SEPARATORS "_" "-")
  endif()

  # Escape regex chars in custom separators
  set(ESCAPED_SEPS "")
  foreach(SEP IN LISTS ARG_NAME_SEPARATORS)
    string(REGEX REPLACE "([][+*?^$().|\\\\-])" "\\\\1" ESCAPED_SEP "${SEP}")
    list(APPEND ESCAPED_SEPS "${ESCAPED_SEP}")
  endforeach()

  string(JOIN "|" SEP_REG ${ESCAPED_SEPS})
  string(REGEX REPLACE "${SEP_REG}" ";" NAME_PIECES "${ARG_NAME}")

  if(NOT ARG_SOURCE_DIR AND NOT ARG_SOURCES)
    message(FATAL_ERROR
      "'etesca_create_tool' (func): No sources were recieved; 'SOURCE_DIR' "
      "and 'SOURCES' are empty?")
  else()
    set(SOURCE_FILES ${ARG_SOURCES})
    if(ARG_SOURCE_DIR)
      file(GLOB_RECURSE DIR_SOURCES CONFIGURE_DEPENDS
        "${ARG_SOURCE_DIR}/*.cpp"
        "${ARG_SOURCE_DIR}/*.cxx"
        "${ARG_SOURCE_DIR}/*.cc"
        "${ARG_SOURCE_DIR}/*.c"
        "${ARG_SOURCE_DIR}/*.hpp"
        "${ARG_SOURCE_DIR}/*.hxx"
        "${ARG_SOURCE_DIR}/*.hh"
        "${ARG_SOURCE_DIR}/*.h")
      list(APPEND SOURCE_FILES ${DIR_SOURCES})
    endif()
  endif()

  if(NOT SOURCE_FILES)
    message(FATAL_ERROR
      "'etesca_create_tool' (func): No valid source files were able to be "
      "resolved for target '${ARG_NAME}'.")
  endif()

  list(GET NAME_PIECES -1 EXPORT_NAME_PIECE)
  list(LENGTH NAME_PIECES PIECES_LEN)
  math(EXPR NS_LEN "${PIECES_LEN} - 1")
  list(SUBLIST NAME_PIECES 0 ${NS_LEN} NAMESPACE_PIECE)

  if(NOT ARG_ALIAS AND NOT ARG_VERBATIM)
    if(PIECES_LEN GREATER 1)
      string(JOIN "::" ARG_ALIAS ${NAME_PIECES})
    else()
      set(ARG_ALIAS "")
    endif()
  endif()

  if(NOT ARG_ROUT_DIR)
    set(ARG_ROUT_DIR "${PROJECT_BINARY_DIR}/bin")
  endif()

  if(NOT ARG_EXPORT_NAME)
    if(NOT ARG_VERBATIM)
      set(ARG_EXPORT_NAME "${EXPORT_NAME_PIECE}")
    else()
      message(FATAL_ERROR
        "'etesca_create_tool' (func): 'EXPORT_NAME' argument is not auto-set "
        "and expected when option 'VERBATIM' is enabled.")
    endif()
  endif()

  if(NOT ARG_EXPORT_NAMESPACE AND NOT ARG_VERBATIM)
    if(NAMESPACE_PIECE)
      string(JOIN "::" NAMESPACE_STR ${NAMESPACE_PIECE})
      set(ARG_EXPORT_NAMESPACE "${NAMESPACE_STR}::")
    else()
      set(ARG_EXPORT_NAMESPACE "")
    endif()
  endif()

  if(NOT ARG_EXPORT_FILE)
    if(NOT ARG_VERBATIM AND NAMESPACE_PIECE)
      string(JOIN "_" FILE_PREFIX ${NAMESPACE_PIECE})
      set(ARG_EXPORT_FILE "${PROJECT_BINARY_DIR}/${FILE_PREFIX}Targets.cmake")
    elseif(NOT ARG_VERBATIM)
      set(ARG_EXPORT_FILE "${PROJECT_BINARY_DIR}/${ARG_NAME}Targets.cmake")
    else()
      message(FATAL_ERROR
        "'etesca_create_tool' (func): Expects 'EXPORT_FILE' when 'VERBATIM' "
        "is enabled.")
    endif()
  endif()

  add_executable(${ARG_NAME} ${SOURCE_FILES})
  if(ARG_ALIAS)
    add_executable(${ARG_ALIAS} ALIAS ${ARG_NAME})
  endif()

  etesca_enable_static_analysis(${ARG_NAME})

  set_target_properties(${ARG_NAME} PROPERTIES
    EXPORT_NAME ${ARG_EXPORT_NAME}
    RUNTIME_OUTPUT_DIRECTORY ${ARG_ROUT_DIR})

  if(NOT ARG_EXPORT_NAMESPACE)
    export(TARGETS ${ARG_NAME}
      APPEND
      FILE "${ARG_EXPORT_FILE}")
  else()
    export(TARGETS ${ARG_NAME}
      APPEND
      NAMESPACE ${ARG_EXPORT_NAMESPACE}
      FILE "${ARG_EXPORT_FILE}")
  endif()
endfunction()
