# Every directory under apps/ that has a CMakeLists.txt is an application,
# switched by ETESCA_APP_<NAME> (ON by default).
file(GLOB app_dirs LIST_DIRECTORIES true CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/*")

foreach(app_dir IN LISTS app_dirs)
  if(NOT IS_DIRECTORY "${app_dir}" OR NOT EXISTS "${app_dir}/CMakeLists.txt")
    continue()
  endif()

  cmake_path(GET app_dir FILENAME app_name)
  string(TOUPPER "${app_name}" app_option)
  string(MAKE_C_IDENTIFIER "ETESCA_APP_${app_option}" app_option)

  option(${app_option} "Build the ${app_name} application" ON)

  if(${app_option})
    add_subdirectory("${app_dir}")
  endif()
endforeach()