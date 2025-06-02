#!/bin/bash

# /etc/pacman.conf 설정 값 수정
echo "pacman 초기 설정 중..."
sed -i 's/^#\?\s*ParallelDownloads\s*=.*/ParallelDownloads = 10/' /etc/pacman.conf
sed -i 's/^\s*CheckSpace/#&/' /etc/pacman.conf
sed -i 's/^#\?\s*VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
echo "완료"
echo ""
