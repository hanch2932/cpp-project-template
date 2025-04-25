#!/bin/bash

# /etc/pacman.conf 설정 값 수정
echo "MSYS2 초기 설정 중..."
sed -i 's/^#\?\s*ParallelDownloads\s*=.*/ParallelDownloads = 10/' /etc/pacman.conf
sed -i 's/^\s*CheckSpace/#&/' /etc/pacman.conf
sed -i 's/^#\?\s*VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
echo "완료"
echo ""

echo "MSYS2 시스템 업데이트 중..."
pacman -Syu --noconfirm
echo "MSYS2 시스템 업데이트 완료"
echo ""

echo "나머지 패키지 업데이트 중..."
pacman -Syu --noconfirm
echo "패키지 업데이트 완료"
echo ""

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

echo "Python 초기 설정 중..."
/ucrt64/bin/python -m venv --system-site-packages ~/python-venv
grep -qxF "export PATH=\"\$HOME/python-venv/bin:\$PATH\"" /etc/profile || echo "export PATH=\"\$HOME/python-venv/bin:\$PATH\"" >> /etc/profile
echo "완료"
echo ""
