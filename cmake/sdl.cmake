include(FetchContent)

set(FETCHCONTENT_BASE_DIR "${CMAKE_OUTPUT_DIR}/third-party")

FetchContent_Declare(
  sdl3
  GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
  GIT_TAG        preview-3.1.6
)

FetchContent_MakeAvailable(sdl3)
