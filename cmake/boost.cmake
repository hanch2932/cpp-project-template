function(include_boost)
  set(TARGET_NAME boost)

  include(FetchContent)

  set(FETCHCONTENT_BASE_DIR "${FETCHCONTENT_BASE_DIR}/${TARGET_NAME}")

  FetchContent_Declare(
    ${TARGET_NAME}
    GIT_REPOSITORY https://github.com/boostorg/boost.git
    GIT_TAG boost-1.87.0
    GIT_SHALLOW TRUE
  )

  FetchContent_MakeAvailable(${TARGET_NAME})
endfunction(include_boost)

include_boost()
