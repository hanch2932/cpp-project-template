# compile_commands.json 파일이 있는 빌드 디렉토리와 복사할 위치 지정
set(COMPILE_COMMANDS_FILE "${CMAKE_BINARY_DIR}/compile_commands.json")
set(DEST_LOCATION "${CMAKE_SOURCE_DIR}/out/build/compile_commands.json")

# compile_commands.json 복사 타깃 생성
add_custom_target(
  copy_compile_commands ALL
  COMMENT "Copying compile_commands.json before build"
)

# compile_commands.json 복사 타깃이 실행될 때 파일 복사를 수행하도록 설정
add_custom_command(
  TARGET copy_compile_commands
  PRE_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different ${COMPILE_COMMANDS_FILE} ${DEST_LOCATION}
  COMMENT "Copying ${COMPILE_COMMANDS_FILE} to ${DEST_LOCATION}"
)
