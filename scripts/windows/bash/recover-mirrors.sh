#!/bin/bash

MIRRORLIST_DIR="/etc/pacman.d"
EXTENSIONS=("clang32" "clang64" "mingw" "mingw32" "mingw64" "msys" "ucrt64")

for ext in "${EXTENSIONS[@]}"; do
  original_file="$MIRRORLIST_DIR/mirrorlist.$ext.bak"
  backup_file="$MIRRORLIST_DIR/mirrorlist.$ext"
  
  # 원본 파일이 존재하는지 확인
  if [ -f "$original_file" ]; then
    cp -v "$original_file" "$backup_file"
  else
    echo "$original_file 파일이 존재하지 않습니다."
  fi
done
