#!/bin/bash

# 백업할 파일들의 확장자를 설정합니다.
MIRRORLIST_DIR="/etc/pacman.d"
EXTENSIONS=("clang32" "clang64" "mingw" "mingw32" "mingw64" "msys" "ucrt64")

# 각 파일을 .bak으로 백업
for ext in "${EXTENSIONS[@]}"; do
    original_file="$MIRRORLIST_DIR/mirrorlist.$ext"
    backup_file="$MIRRORLIST_DIR/mirrorlist.$ext.bak"
    
    # 원본 파일이 존재하는지 확인
    if [ -f "$original_file" ]; then
        # 백업 파일이 이미 존재하는지 확인
        if [ -f "$backup_file" ]; then
            echo "$backup_file 파일이 이미 존재합니다. 백업을 건너뜁니다."
        else
            # 백업 파일이 존재하지 않으면 백업 수행
            cp "$original_file" "$backup_file"
            echo "$original_file -> $backup_file 백업 완료"
        fi
    else
        echo "$original_file 파일이 존재하지 않습니다."
    fi
done

# 서버 주소만 추출하여 배열에 저장
all_mirrors=(
    "https://mirror.iscas.ac.cn/msys2/mingw"
    "https://mirrors.ustc.edu.cn/msys2/mingw"
    "https://mirrors.bfsu.edu.cn/msys2/mingw"
    "https://mirrors.dotsrc.org/msys2/mingw"
    "https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw"
    "https://mirror.msys2.org/mingw"
    "https://repo.msys2.org/mingw"
)

echo "미러리스트 파일 저장"
for ext in "${EXTENSIONS[@]}"; do
    filename="mirrorlist.$ext"
    filepath="$MIRRORLIST_DIR/$filename"
    
    > "$filepath"
    for url in "${all_mirrors[@]}"; do
        # ext가 msys일 경우 $arch로 변경
        if [ "$ext" = "msys" ]; then
            ext="\$arch"
            url="${url/mingw/msys}"
        fi
        
        if [ "$ext" = "mingw" ]; then
            ext="\$repo"
        fi
        
        # if [ "$ext" = "mingw32" ]; then
        #     ext="i686"
        # fi
        
        # if [ "$ext" = "mingw64" ]; then
        #     ext="x86_64"
        # fi
        # 변환된 주소를 파일에 저장
        echo "Server = $url/$ext/" >> "$filepath"
    done
done
