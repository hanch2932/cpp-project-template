cmake_minimum_required(VERSION 3.30.0)

project(
  cpp-template
  VERSION 0.1.0
  LANGUAGES C CXX
)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

set(CMAKE_OUTPUT_DIR "${CMAKE_SOURCE_DIR}/out")
set(FETCHCONTENT_BASE_DIR "${CMAKE_BINARY_DIR}/fetch-content")

# 컴파일러 식별자 확인
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang") # clang compiler
  # Clang 컴파일러를 사용할 때
  message("\nUse ${CMAKE_CXX_COMPILER_ID} compiler")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -pedantic")

  if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    link_libraries(stdc++exp) # print, println 함수를 사용하기 위해 링크
  endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU") # GCC compiler
  # GCC 컴파일러를 사용할 때
  message("\nUse ${CMAKE_CXX_COMPILER_ID} compiler")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -pedantic")

  if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    link_libraries(stdc++exp) # print, println 함수를 사용하기 위해 링크
  endif()
else()
  message("\nUnkown compiler")
endif()

message("CMake CXX Compiler ID: ${CMAKE_CXX_COMPILER_ID}")
message("CMake CXX Compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
message("CMake CXX Compiler options: ${CMAKE_CXX_FLAGS}")
message("OS: ${CMAKE_HOST_SYSTEM_NAME}")
message("")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

include(sdl)
include(glfw)

# include(boost)
include(imgui)
include(cryptopp)

add_subdirectory(src)

# compile_commands.json 파일이 있는 빌드 디렉토리와 복사할 위치 지정
set(COMPILE_COMMANDS_FILE "${CMAKE_BINARY_DIR}/compile_commands.json")
set(DEST_LOCATION "${CMAKE_SOURCE_DIR}/out/build/compile_commands.json")

# compile_commands.json 복사 타깃 생성
add_custom_target(
  copy_compile_commands ALL
  COMMENT "Copying compile_commands.json after build"
)

# compile_commands.json 복사 타깃이 실행될 때 파일 복사를 수행하도록 설정
add_custom_command(
  TARGET copy_compile_commands
  PRE_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different ${COMPILE_COMMANDS_FILE} ${DEST_LOCATION}
  COMMENT "Copying ${COMPILE_COMMANDS_FILE} to ${DEST_LOCATION}"
)
