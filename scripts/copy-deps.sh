#!/bin/bash

# 매개변수 개수 확인
if [ "$#" -ne 3 ]; then
  echo "How to use: $0 os_name target_dir exec_path(no ext)"
  exit 1
fi

OS="$1"
TARGET_DIR="$2"
EXEC_PATH="$3"

if [ "$OS" == "Windows" ]; then
  PROGRAM="$EXEC_PATH.exe"
  rm -vrf "$TARGET_DIR/*.dll"
  LIBS=$(ldd "$PROGRAM" | grep "=> /ucrt64" | awk '{print $3}')
elif [ "$OS" == "Linux" ]; then
  PROGRAM="$EXEC_PATH"
  rm -vrf "$TARGET_DIR/*.so"
  LIBS=$(ldd "$PROGRAM" | grep "=> /" | awk '{print $3}')
else
  echo "Invalid OS"
  exit 1
fi

echo "Delete all Shared library files in $TARGET_DIR"

if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
fi

for LIB in $LIBS; do
  cp -v "$LIB" "$TARGET_DIR"
done

if [ "$OS" == "Windows" ]; then
  EXTRA_PATH="/ucrt64/share/qt6/plugins/platforms"
  EXTRA_LIBS=("qdirect2d.dll" "qminimal.dll" "qoffscreen.dll" "qwindows.dll")
  EXTRA_DEST_PATH="$TARGET_DIR/platforms"

  mkdir -p "$EXTRA_DEST_PATH"

  for EXTRA_LIB in ${EXTRA_LIBS[@]}; do
    cp -v "$EXTRA_PATH/$EXTRA_LIB" "$EXTRA_DEST_PATH"
  done
fi

echo "All libraries copied to $TARGET_DIR"
