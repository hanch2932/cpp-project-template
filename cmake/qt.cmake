function(include_qt)
  set(TARGET_NAME qt)

  include(FetchContent)

  set(FETCHCONTENT_BASE_DIR "${FETCHCONTENT_BASE_DIR}/${TARGET_NAME}")

  FetchContent_Declare(
    ${TARGET_NAME}
    GIT_REPOSITORY https://github.com/qt/qtbase.git
    GIT_TAG v6.8.1
    GIT_SHALLOW TRUE
  )

  FetchContent_MakeAvailable(${TARGET_NAME})
endfunction(include_qt)

include_qt()
