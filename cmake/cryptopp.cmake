include(FetchContent)

set(FETCHCONTENT_BASE_DIR "${CMAKE_OUTPUT_DIR}/third-party")

FetchContent_Declare(
  cryptopp
  GIT_REPOSITORY https://github.com/weidai11/cryptopp.git
  GIT_TAG        CRYPTOPP_8_9_0
  GIT_SHALLOW    TRUE
)

FetchContent_MakeAvailable(cryptopp)

set(CRYPTOPP_DIR ${cryptopp_SOURCE_DIR})

set(TARGET_NAME cryptopp)

file(GLOB SRC_FILES ${CRYPTOPP_DIR}/*.cpp)
add_library(
    ${TARGET_NAME}
    STATIC
    ${SRC_FILES}
)

target_include_directories(
    ${TARGET_NAME}
    PRIVATE
    ${CRYPTOPP_DIR}
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
