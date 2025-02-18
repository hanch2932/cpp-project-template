set(TARGET_NAME imgui-demo)

add_executable(${TARGET_NAME})

target_sources(
  ${TARGET_NAME}
  PRIVATE
  main.cpp
)

target_link_libraries(
  ${TARGET_NAME}
  PRIVATE
  third-party
)
