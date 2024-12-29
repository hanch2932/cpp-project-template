function(include_imgui)
  set(TARGET_NAME imgui)

  include(FetchContent)

  set(FETCHCONTENT_BASE_DIR "${FETCHCONTENT_BASE_DIR}/${TARGET_NAME}")

  FetchContent_Declare(
    ${TARGET_NAME}
    GIT_REPOSITORY https://github.com/ocornut/imgui.git
    GIT_TAG v1.91.6-docking
    GIT_SHALLOW TRUE
  )

  FetchContent_MakeAvailable(${TARGET_NAME})

  set(IMGUI_DIR ${imgui_SOURCE_DIR})

  find_package(SDL2 REQUIRED)
  find_package(OpenGL REQUIRED)

  add_library(
    ${TARGET_NAME}
    STATIC
    ${IMGUI_DIR}/imgui_demo.cpp
    ${IMGUI_DIR}/imgui_draw.cpp
    ${IMGUI_DIR}/imgui_tables.cpp
    ${IMGUI_DIR}/imgui_widgets.cpp
    ${IMGUI_DIR}/imgui.cpp
    ${IMGUI_DIR}/backends/imgui_impl_sdl2.cpp
    ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
    ${IMGUI_DIR}/misc/cpp/imgui_stdlib.cpp
  )

  target_include_directories(
    ${TARGET_NAME}
    PUBLIC
    ${IMGUI_DIR}

    # 이 타겟을 빌드할 때는 사용하지 않아도 되지만, 다른 타겟이 이 타겟을 사용할 때 필요할 수 있음
    ${IMGUI_DIR}/backends
    ${IMGUI_DIR}/misc/cpp
  )

  target_link_libraries(
    ${TARGET_NAME}
    PUBLIC
    ${OPENGL_LIBRARIES}
    SDL2::SDL2
  )
endfunction(include_imgui)

include_imgui()
