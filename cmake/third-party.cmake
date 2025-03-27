find_package(Vulkan REQUIRED)
find_package(SDL3)
if(NOT SDL3_FOUND)
  message("SDL3 패키지를 찾을 수 없습니다. 직접 빌드합니다.")
  include(sdl)
endif()

include(imgui)
include(google-test)

add_library(
  third-party
  INTERFACE
)

target_link_libraries(
  third-party
  INTERFACE
  imgui # sdl3 포함
)
