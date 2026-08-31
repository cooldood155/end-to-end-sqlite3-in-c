add_library(etesca_warnings INTERFACE)
add_library(etesca::warnings ALIAS etesca_warnings)
set_target_properties(etesca_warnings PROPERTIES EXPORT_NAME warnings)

set(gnu_like
  -Wall
  -Wextra
  -Wpedantic
  -Wshadow
  -Wnon-virtual-dtor
  -Wold-style-cast
  -Wcast-align
  -Wsign-conversion
  -Wnull-dereference
  -Wdouble-promotion
  -Wformat=2
  -Wimplicit-fallthrough)

set(msvc_like
  /W4
  /permissive-
  /w14640
  /w14826)

target_compile_options(etesca_warnings INTERFACE
  "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang,IntelLLVM>:${gnu_like}>"
  "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:${msvc_like}>")

if(ETESCA_WERROR)
  target_compile_options(etesca_warnings INTERFACE
    "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang,IntelLLVM>:-Werror>"
    "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/WX>")
endif()
