include(FetchContent)

set(FETCHCONTENT_BASE_DIR "${CMAKE_OUTPUT_DIR}/third-party")

FetchContent_Declare(
  boost
  GIT_REPOSITORY https://github.com/boostorg/boost.git
  GIT_TAG        boost-1.87.0
)

FetchContent_MakeAvailable(boost)
