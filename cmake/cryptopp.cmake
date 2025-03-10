function(include_cryptopp)
  set(TARGET_NAME cryptopp)

  include(FetchContent)

  set(FETCHCONTENT_BASE_DIR "${FETCHCONTENT_BASE_DIR}/${TARGET_NAME}")

  FetchContent_Declare(
    ${TARGET_NAME}
    GIT_REPOSITORY https://github.com/weidai11/cryptopp.git
    GIT_TAG CRYPTOPP_8_9_0
    GIT_SHALLOW TRUE
    SOURCE_DIR ${FETCHCONTENT_BASE_DIR}/${TARGET_NAME}
  )

  FetchContent_MakeAvailable(${TARGET_NAME})

  set(CRYPTOPP_DIR ${${TARGET_NAME}_SOURCE_DIR})

  add_library(${TARGET_NAME} STATIC)

  file(GLOB SRC_FILES ${CRYPTOPP_DIR}/*.cpp)
  target_sources(
    ${TARGET_NAME}
    PRIVATE
    ${SRC_FILES}
  )

  target_include_directories(
    ${TARGET_NAME}
    PUBLIC
    ${CRYPTOPP_DIR}
    ${CRYPTOPP_DIR}/..
  )

  target_compile_options(
    ${TARGET_NAME}
    PRIVATE
    -mssse3
    -msse4.1
    -mavx
    -mavx2
    -mcrc32
    -mpclmul
    -msha
    -maes
  )
endfunction(include_cryptopp)

include_cryptopp()
