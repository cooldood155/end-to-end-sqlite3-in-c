set(ETESCA_CLANG_TIDY_COMMAND "")
set(ETESCA_CPPCHECK_COMMAND "")

set(ETESCA_SA_OUTPUT "console" CACHE STRING
  "Where analyser findings go: console, or files to also write per-source reports")
set_property(CACHE ETESCA_SA_OUTPUT PROPERTY STRINGS console files)

set(ETESCA_SA_OUTPUT_DIR "${PROJECT_BINARY_DIR}/analysis" CACHE PATH
  "Directory for per-source analyser reports when ETESCA_SA_OUTPUT is files")

set(ETESCA_SA_MESSAGE_FORMAT "default" CACHE STRING
  "cppcheck message format: default, gcc or vs")
set_property(CACHE ETESCA_SA_MESSAGE_FORMAT PROPERTY STRINGS default gcc vs)

if(NOT ETESCA_SA_OUTPUT MATCHES "^(console|files)$")
  message(FATAL_ERROR
    "ETESCA_SA_OUTPUT must be console or files, not `${ETESCA_SA_OUTPUT}`")
endif()

if(NOT ETESCA_SA_MESSAGE_FORMAT MATCHES "^(default|gcc|vs)$")
  message(FATAL_ERROR
    "ETESCA_SA_MESSAGE_FORMAT must be default, gcc or vs, not
    '${ETESCA_SA_MESSAGE_FORMAT}`")
endif()

function(etesca_analyser_version out program)
  execute_process(
    COMMAND "${program}" --version
    OUTPUT_VARIABLE version_banner
    ERROR_VARIABLE version_banner
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  if(banner MATCHES "(([0-9]+\.){2,3})")
    set(${out} "${CMAKE_MATCH_1}")
  else()
    set(${out} "unknown" PARENT_SCOPE)
  endif()
endfunction()

if(ETESCA_SA_ALL OR ETESCA_SA_CLANG_TIDY)
  find_program(ETESCA_CLANG_TIDY_PATH
    NAMES
      clang-tidy
      clang-tidy-22
      clang-tidy-21
      clang-tidy-20
      clang-tidy-19
      clang-tidy-18
    REQUIRED)

  set(ETESCA_CLANG_TIDY_COMMAND
    "${ETESCA_CLANG_TIDY_PATH}"
    "--extra-arg=-Wno-unknown-warning-option"
    "--extra-arg=-Wno-unused-command-line-argument")

  if(ETESCA_SA_OUTPUT STREQUAL "files")
    find_program(ETESCA_SH_PATH NAMES sh REQUIRED)

    file(MAKE_DIRECTORY "${ETESCA_SA_OUTPUT_DIR}/clang-tidy")

    list(PREPEND ETESCA_CLANG_TIDY_COMMAND
      "${ETESCA_SH_PATH}"
      "${PROJECT_SOURCE_DIR}/cmake/analyser-laucher.sh"
      "${ETESCA_SA_OUTPUT_DIR}/clang-tidy")
  endif()

  if(ETESCA_WERROR)
    list(APPEND ETESCA_CLANG_TIDY_COMMAND "--warnings-as-errors=*")
  endif()

  etesca_analyser_version(etesca_tidy_version "${ETESCA_CLANG_TIDY_PATH}")
  message(STATUS "etesca: clang-tidy ${etesca_tidy_version} enabled (${ETESCA_CLANG_TIDY_PATH})")
endif()

if(ETESCA_SA_ALL OR ETESCA_SA_CPPCHECK)
  find_program(ETESCA_CPPCHECK_PATH NAMES cppcheck REQUIRED)

  set(ETESCA_CPPCHECK_COMMAND
    "${ETESCA_CPPCHECK_PATH}"
    "--enable=warning,style,performance,portability"
    "--inline-suppr"
    "--suppress=missingInclude"
    "--suppress=missingIncludeSystem"
    "--suppress=unusedFunction"
    "--suppress=unmatchedSuppression"
    "--suppress=checkersReport"
    "--suppress=normalCheckLevelMaxBranches")

  if(NOT ETESCA_SA_MESSAGE_FORMAT STREQUAL "default")
    list(APPEND ETESCA_CPPCHECK_COMMAND "--template=${ETESCA_SA_MESSAGE_FORMAT}")
  endif()

  if(ETESCA_SA_OUTPUT STREQUAL "files")
    file(MAKE_DIRECTORY "${ETESCA_SA_OUTPUT_DIR}/cppcheck")
    list(APPEND ETESCA_CPPCHECK_COMMAND "--plist-output=${ETESCA_SA_OUTPUT_DIR}/cppcheck")
  endif()

  if(ETESCA_WERROR)
    list(APPEND ETESCA_CPPCHECK_COMMAND "--error-exitcode=1")
  endif()

  etesca_analyser_version(etesca_cppcheck_version "${ETESCA_CPPCHECK_PATH}")
  message(STATUS "etesca: cppcheck ${etesca_cppcheck_version} enabled (${ETESCA_CPPCHECK_PATH})")
endif()

if(ETESCA_SA_OUTPUT STREQUAL "files" AND (ETESCA_CLANG_TIDY_COMMAND OR ETESCA_CPPCHECK_COMMAND))
  message(STATUS "etesca: analyser reports under ${ETESCA_SA_OUTPUT_DIR}")
endif()

function(etesca_enable_static_analysis target)
  if(ETESCA_CLANG_TIDY_COMMAND)
    set_target_properties(${target} PROPERTIES CXX_CLANG_TIDY "${ETESCA_CLANG_TIDY_COMMAND}")
  endif()

  if(ETESCA_CPPCHECK_COMMAND)
    set_target_properties(${target} PROPERTIES CXX_CPPCHECK "${ETESCA_CPPCHECK_COMMAND}")
  endif()
endfunction()
