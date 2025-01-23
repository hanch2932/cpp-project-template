set(TARGET_NAME imgui-demo)

add_executable(
  ${TARGET_NAME}
  main.cpp
)

target_link_libraries(
  ${TARGET_NAME}
  PRIVATE
  third-party
)
