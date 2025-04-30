cmake_minimum_required(VERSION 3.30.0)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

project(
  cpp-template
  VERSION 0.1.0
  LANGUAGES C CXX
)

message("")
message("OS: ${CMAKE_HOST_SYSTEM_NAME}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

set(FETCHCONTENT_BASE_DIR "${CMAKE_BINARY_DIR}/fetch-content")

# 컴파일러 식별자 확인
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang") # gcc/clang compiler
  # Clang 컴파일러를 사용할 때
  message("Use ${CMAKE_CXX_COMPILER_ID} compiler")
  # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -pedantic")
  add_compile_options(-Wall -Wextra -pedantic)

  if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    link_libraries(stdc++exp) # print, println 함수를 사용하기 위해 링크
  endif()
else()
  message(FATAL_ERROR "Unsupported compiler")
endif()

get_directory_property(CURRENT_DIR_COMPILE_OPTIONS COMPILE_OPTIONS)

message("CMake CXX Compiler ID: ${CMAKE_CXX_COMPILER_ID}")
message("CMake CXX Compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
message("CMake CXX Compiler options: ${CURRENT_DIR_COMPILE_OPTIONS}")
message("")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

include(third-party)

add_subdirectory(src)

include(copy_compile_commands)
