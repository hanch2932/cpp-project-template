include(FetchContent)

set(FETCHCONTENT_BASE_DIR "${CMAKE_OUTPUT_DIR}/third-party")

FetchContent_Declare(
  glfw
  GIT_REPOSITORY https://github.com/glfw/glfw.git
  GIT_TAG        3.4
)

FetchContent_MakeAvailable(glfw)
