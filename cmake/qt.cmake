include(FetchContent)

set(FETCHCONTENT_BASE_DIR "${CMAKE_OUTPUT_DIR}/third-party")

FetchContent_Declare(
  qt
  GIT_REPOSITORY https://github.com/qt/qtbase.git
  GIT_TAG        v6.8.1
)

FetchContent_MakeAvailable(qt)
