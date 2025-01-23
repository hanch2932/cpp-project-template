function(include_imgui)
  set(TARGET_NAME imgui)

  include(FetchContent)

  set(FETCHCONTENT_BASE_DIR "${FETCHCONTENT_BASE_DIR}/${TARGET_NAME}")

  FetchContent_Declare(
    ${TARGET_NAME}
    GIT_REPOSITORY https://github.com/ocornut/imgui.git
    GIT_TAG v1.91.7-docking
    GIT_SHALLOW TRUE
  )

  FetchContent_MakeAvailable(${TARGET_NAME})

  set(IMGUI_DIR ${${TARGET_NAME}_SOURCE_DIR})

  find_package(Vulkan REQUIRED)

  add_library(
    ${TARGET_NAME}
    STATIC
    ${IMGUI_DIR}/imgui_demo.cpp
    ${IMGUI_DIR}/imgui_draw.cpp
    ${IMGUI_DIR}/imgui_tables.cpp
    ${IMGUI_DIR}/imgui_widgets.cpp
    ${IMGUI_DIR}/imgui.cpp
    ${IMGUI_DIR}/backends/imgui_impl_sdl3.cpp
    ${IMGUI_DIR}/backends/imgui_impl_vulkan.cpp
    ${IMGUI_DIR}/misc/cpp/imgui_stdlib.cpp
  )

  target_include_directories(
    ${TARGET_NAME}
    PUBLIC
    ${IMGUI_DIR}
    ${IMGUI_DIR}/backends
    ${IMGUI_DIR}/misc/cpp
  )

  target_link_libraries(
    ${TARGET_NAME}
    PUBLIC
    Vulkan::Vulkan
    SDL3::SDL3
  )

  target_compile_definitions(
    ${TARGET_NAME}
    PUBLIC
    IMGUI_USE_WCHAR32
  )
endfunction(include_imgui)

include_imgui()
