# --- External Kitware Functions ---
include(CheckCXXCompilerFlag)
include(CheckLinkerFlag)
include(CheckIPOSupported)

set(ETESCA_SANITIZE "" CACHE STRING
    "Comma-separated sanitizers to build with, e.g. address, undefined, or
    thread; address, thread, leak, memory, and undefined are the sanitizers")

option(ETESCA_HARDENING    "Compile and link with hardening flags"        ON)
option(ETESCA_COVERAGE     "Instrument for coverage"                      OFF)
option(ETESCA_REPRODUCIBLE "Strip build paths out of binaries"            OFF)
option(ETESCA_LTO          "Enable interprocedural optimization"          OFF)
option(ETESCA_CCACHE       "Use ccache or sccache when one is installed"  ON)
option(ETESCA_REDUCE_SIZE  "Strip unecessary/dead code and unroll loops"  ON)

add_library(etesca_options INTERFACE)
add_library(etesca::options ALIAS etesca_options)
set_target_properties(etesca_options PROPERTIES EXPORT_NAME options)

set(gnu_like_compiler "$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang,IntelLLVM>")
set(msvc_compiler "$<COMPILE_LANG_AND_ID:CXX,MSVC>")

if(CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "GNU")
  set(compiler_like_gnu ON CACHE INTERNAL "")
  set(compiler ${gnu_like_compiler})
elseif(CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
  set(compiler_is_msvc ON CACHE INTERNAL "")
  set(compiler ${msvc_compiler})
else()
  message(FATAL_ERROR "Unsupported compiler front-end: ${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}")
endif()

function(etesca_try_compile_option flag)
  string(MAKE_C_IDENTIFIER "etesca_has_c_${flag}" probe)
  check_cxx_compiler_flag("${flag}" ${probe})

  if(${probe})
    target_compile_options(etesca_options INTERFACE "$<${compiler}:${flag}>")
  endif()
endfunction()

function(etesca_try_link_option flag)
  string(MAKE_C_IDENTIFIER "etesca_has_l_${flag}" probe)
  check_linker_flag(CXX "${flag}" ${probe})

  if(${probe})
    target_compile_options(etesca_options INTERFACE "$<${compiler}:${flag}>")
  endif()
endfunction()

if(ETESCA_SANITIZE)
  string(REPLACE "," ";" etesca_sanitizer_list "${ETESCA_SANITIZE}")

  foreach(etesca_sanitizer IN_LIST etesca_sanitizer_list)
    if(NOT etesca_sanitizer MATCHES "^(address|thread|leak|memory|undefined)$")
      message(FATAL_ERROR
        "ETESCA_SANITIZE entries must be address, thread, leak, memory or
        undefined, NOT '${etesca_sanitizer}'")
    endif()

    if(compiler_is_msvc AND NOT etesca_sanitizer STREQUAL "address")
      message(FATAL_ERROR "MSVC only natively supports tha 'address' sanitizer. '${etesca_sanitizer}' is not supported")
    endif()
  endforeach()

  if("thread" IN_LIST etesca_sanitizer_list)
    foreach(etesca_conflict address leak memory)
      if("${etesca_conflict}" IN_LIST etesca_sanitizer_list)
        message(FATAL_ERROR
          "The thread sanitizer cannot be combined with ${etesca_conflict}")
      endif()
    endforeach()
  endif()

  if(compiler_like_gnu)
    set(etesca_sanitize_flag "-fsanitize=${ETESCA_SANITIZE}")

    target_compile_options(etesca_options INTERFACE
      "$<${gnu_like_compiler}:${etesca_sanitize_flag}>")
    target_link_options(etesca_options INTERFACE
      "$<${gnu_like_compiler}:${etesca_sanitize_flag}>")

  elseif(compiler_is_msvc)
    set(etesca_sanitize_flag "/fsanitize=address")

    target_compile_options(etesca_options INTERFACE
      "$<${msvc_compiler}:${etesca_sanitize_flag}>"
      "$<${msvc_compiler}:/Zi>") # Required for ASan symbols
    target_link_options(etesca_options INTERFACE
      "$<${msvc_compiler}:${etesca_sanitize_flag}>"
      "$<${msvc_compiler}:/INCREMENTAL:NO>") # ASan breaks incremental linking
  endif()

  string(MAKE_C_IDENTIFIER "ETESCA_HAS_SANITIZE_${ETESCA_SANITIZE}" etesca_sanitize_probe)

  set(CMAKE_REQUIRED_LINK_OPTIONS "${etesca_sanitize_flag}")
  check_cxx_compiler_flag("${etesca_sanitize_flag}" ${etesca_sanitize_probe})
  unset(CMAKE_REQUIRED_LINK_OPTIONS)

  if(NOT ${etesca_sanitize_probe})
    message(FATAL_ERROR
      "This toolchain cannot build with ${etesca_sanitize_flag}; the runtime
      library is probably not installed")
  endif()

  if(compiler_like_gnu)
    target_compile_options(etesca_options INTERFACE
      "$<${gnu_like_compiler}:${etesca_sanitize_flag}>"
      "$<${gnu_like_compiler}:-fno-omit-frame-pointer>"
      "$<${gnu_like_compiler}:-g>")
  elseif(compiler_is_msvc)
    target_compile_options(etesca_options INTERFACE 
      "$<${msvc_compiler}:${etesca_sanitize_flag}>"
      "$<${msvc_compiler}:/Zi>"
      "$<${msvc_compiler}:/Oy->")
    endif()

    if(compiler_is_msvc)
      # Force ALL optimized configurations to keep frame pointers
      foreach(config RELEASE RELWITHDEBINFO MINSIZEREL)
        string(REPLACE "/O2" "/O2 /Oy-" CMAKE_CXX_FLAGS_${config} "${CMAKE_CXX_FLAGS_${config}}")
        string(REPLACE "/O1" "/O1 /Oy-" CMAKE_CXX_FLAGS_${config} "${CMAKE_CXX_FLAGS_${config}}")
        string(REPLACE "/Oy- /Oy-" "/Oy-" CMAKE_CXX_FLAGS_${config} "${CMAKE_CXX_FLAGS_${config}}")
      endforeach()
    endif()

    target_link_options(etesca_options INTERFACE
      "$<${compiler}:${etesca_sanitize_flag}>")
    
      message(STATUS "etesca: sanitizers ${ETESCA_SANITIZE}")
endif()

if(ETESCA_HARDENING)
  if(compiler_like_gnu)
    # Stack-based buffer overflow ("stack smashing") attacks
    etesca_try_compile_option(-fstack-protector-strong)

    # Enables page-by-page memory probing during stack allocation
    etesca_try_compile_option(-fstack-clash-protection)

    # Control flow integrity / shadow stack (if hardware supports it)
    etesca_try_compile_option(-fcf-protection=full)

    # Uninitialized stack variables
    etesca_try_compile_option(-ftrivial-auto-var-init=zero)

    # Enable libstdc++ bounds checking assertions
    target_compile_definitions(
      etesca_options INTERFACE "$<${gnu_like_compiler}:_GLIBCXX_ASSERTIONS>")

    # Security-critical info can be marked as read-only by OS
    etesca_try_link_option(LINKER:-z,relro)

    # Dynamic linker resolves all dynamic function addresses upon program start
    etesca_try_link_option(LINKER:-z,now)

    # Program's stack memory segment is non-executable
    etesca_try_link_option(LINKER:-z,noexecstack)

  elseif(compiler_is_msvc)
    # Stack-based buffer overflow ("stack smashing") attacks
    etesca_try_compile_option(/GS)

    # Control flow integrity / shadow attack
    etesca_try_compile_option(/guard:cf)
    etesca_try_link_option(/guard:cf)

    # Enforce data execution prevention (DEP) & ASLR
    etesca_try_link_option(/NXCOMPAT)

    # Address space layout randomization (ASLR)
    etesca_try_link_option(/DYNAMICBASE)

    # Uninitialized stack variables
    etesca_try_compile_option(/initall)

    # Enable 64-bit ASLR
    etesca_try_link_option(/HIGHENTROPYVA)
  endif()

  if(NOT ETESCA_SANITIZE)
    target_compile_definitions(etesca_options INTERFACE 
      "$<$<AND:${gnu_like_compiler},$<NOT:$<CONFIG:Debug>>>:_FORTIFY_SOURCE=3>")

    target_compile_definitions(etesca_options INTERFACE 
      "$<$<AND:${msvc_compiler},$<NOT:$<CONFIG:Debug>>>:_SECURE_SCL=1>")
  endif()

  message(STATUS "etesca: hardening enabled")
endif()

if(ETESCA_COVERAGE)
  if(compiler_like_gnu)
    target_compile_options(etesca_options INTERFACE 
      "$<${gnu_like_compiler}:--coverage>" 
      "$<${gnu_like_compiler}:-g>" 
      "$<${gnu_like_compiler}:-O0>")
    target_link_options(etesca_options INTERFACE 
      "$<${gnu_like_compiler}:--coverage>")

  elseif(compiler_is_msvc)
    target_compile_options(etesca_options INTERFACE 
      "$<${msvc_compiler}:/Zi>"
      "$<${msvc_compiler}:/Od>")
    target_link_options(etesca_options INTERFACE 
      "$<${msvc_compiler}:/DEBUG>")
  endif()

  message(STATUS "etesca: coverage instrumentation enabled")
endif()

if(ETESCA_REPRODUCIBLE)
  if(compiler_like_gnu)
    # Strip absolute build paths from compiled binaries
    etesca_try_compile_option("-ffile-prefix-map=${PROJECT_SOURCE_DIR}=.")

    # Prevents compiler from injecting its own version and name metadata into
    # the compiled object files and final binaries
    etesca_try_compile_option(-fno-ident)

  elseif(compiler_is_msvc)
    # Remap paths (equivalent to -ffile-prefix-map)
    etesca_try_compile_option("/pathmap:${PROJECT_SOURCE_DIR}=.")

    # Make builds deterministic (remove variable timestamps and telementry IDs)
    etesca_try_compile_option("/experimental:deterministic")

    # Prevent the linker from embedding absolute path to local PDB file
    etesca_try_link_option("/PDBALTPATH:%_PDB%")
  endif()

  message(STATUS "etesca: build paths mapped out of binaries")
endif()

if(ETESCA_LTO)
  # Check for Interprocedural Optimization (IPO)
  check_ipo_supported(RESULT etesca_ipo_supported OUTPUT etesca_ipo_error)

  if(etesca_ipo_supported)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    message(STATUS "etesca: interprocedural optimization enabled")
  else()
    message(FATAL_ERROR "ETESCA_LTO is on but this toolchain cannot do it: ${etesca_ipo_error}")
  endif()
endif()

if(ETESCA_CCACHE AND NOT CMAKE_CXX_COMPILER_LAUNCHER)
  find_program(ETESCA_COMPILER_CACHE NAMES ccache sccache)

  if(ETESCA_COMPILER_CACHE)
    set(CMAKE_CXX_COMPILER_LAUNCHER "${ETESCA_COMPILER_CACHE}")
    message(STATUS "etesca: compiler cache ${ETESCA_COMPILER_CACHE}")
  endif()
endif()

if(ETESCA_REDUCE_SIZE)
  if(compiler_like_gnu)
    # Delets unused code sections ones (deletes dead code)
    etesca_try_link_option("LINKER:--gc-sections")

    # Groups functions into sections instead of bundling all found functions of
    # a file into one massive block
    etesca_try_compile_option(-ffunction-sections)

    # Groups global and static variables into sections instead of bundling all
    # found instances of such into one massive block
    etesca_try_compile_option(-fdata-sections)

  elseif(compiler_is_msvc)
    # Enables function-level linking (equivalent to --ffunction-sections /
    # -fdata-sections)
    etesca_try_compile_option(/Gy)

    # Eliminates functions and data that ar enever referenced (equivalent to
    # --gc-sections)
    etesca_try_link_option(/OPT:REF)

    # Remove redundant COMDATs (further minimizes binary footprint on MSVC)
    etesca_try_link_option(/OPT:ICF)
  endif()
endif()
