include(FetchContent)

set(FETCHCONTENT_BASE_DIR "${CMAKE_OUTPUT_DIR}/third-party")

FetchContent_Declare(
  imgui
  GIT_REPOSITORY https://github.com/ocornut/imgui.git
  GIT_TAG        v1.91.6-docking
  GIT_SHALLOW    TRUE
)

FetchContent_MakeAvailable(imgui)

set(IMGUI_DIR ${imgui_SOURCE_DIR})

find_package(OpenGL REQUIRED)
find_package(Vulkan REQUIRED)

set(TARGET_NAME imgui)
add_library(
  ${TARGET_NAME}
  STATIC
  ${IMGUI_DIR}/imgui_demo.cpp
  ${IMGUI_DIR}/imgui_draw.cpp
  ${IMGUI_DIR}/imgui_tables.cpp
  ${IMGUI_DIR}/imgui_widgets.cpp
  ${IMGUI_DIR}/imgui.cpp
  ${IMGUI_DIR}/backends/imgui_impl_sdl3.cpp
  ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
  ${IMGUI_DIR}/backends/imgui_impl_vulkan.cpp
  ${IMGUI_DIR}/backends/imgui_impl_glfw.cpp
  ${IMGUI_DIR}/misc/cpp/imgui_stdlib.cpp
)

target_include_directories(
  ${TARGET_NAME}
  PUBLIC
  ${IMGUI_DIR}

  # 이 타겟을 빌드할 때는 사용하지 않아도 되지만, 다른 타겟이 이 타겟을 사용할 때 필요할 수 있음
  ${IMGUI_DIR}/backends
  ${IMGUI_DIR}/misc/cpp

  ${Vulkan_INCLUDE_DIRS}
)

target_link_libraries(
  ${TARGET_NAME}
  PUBLIC
  ${OPENGL_LIBRARIES}
  SDL3::SDL3
  Vulkan::Vulkan
  glfw
)
