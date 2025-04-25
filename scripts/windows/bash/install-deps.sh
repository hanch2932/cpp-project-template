#!/bin/bash

echo "프로젝트 개발환경 관련 패키지 설치 중..."
pacman -Sy --noconfirm --needed \
            base-devel \
            bc \
            mingw-w64-ucrt-x86_64-toolchain \
            mingw-w64-ucrt-x86_64-clang \
            mingw-w64-ucrt-x86_64-clang-tools-extra \
            mingw-w64-ucrt-x86_64-ninja \
            mingw-w64-ucrt-x86_64-cmake \
            mingw-w64-ucrt-x86_64-gettext-tools \
            mingw-w64-ucrt-x86_64-doxygen \
            mingw-w64-ucrt-x86_64-python-pip
echo "패키지 설치 완료"
echo ""

echo "추가 종속성 패키지 설치 중..."
pacman -Sy --noconfirm --needed \
            mingw-w64-ucrt-x86_64-sdl3 \
            mingw-w64-ucrt-x86_64-vulkan-devel
echo "패키지 설치 완료"
echo ""
