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

target_compile_definitions(
  ${TARGET_NAME}
  PRIVATE
    IMGUI_DEMO_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
)
