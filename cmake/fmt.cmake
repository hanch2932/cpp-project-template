function(include_fmt)
  set(TARGET_NAME fmt)

  include(FetchContent)

  set(FETCHCONTENT_BASE_DIR "${FETCHCONTENT_BASE_DIR}/${TARGET_NAME}")

  FetchContent_Declare(
    ${TARGET_NAME}
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG 11.1.1
    GIT_SHALLOW TRUE
  )

  FetchContent_MakeAvailable(${TARGET_NAME})
endfunction(include_fmt)

include_fmt()
