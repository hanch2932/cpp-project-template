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

mirrorlist="$MIRRORLIST_DIR/mirrorlist.ucrt64.bak"
mirror_urls=$(grep '^Server' "$mirrorlist" | awk '{print $3}' | sed 's|/ucrt64/||')

# 미러 서버 응답 속도 테스트
echo "Testing mirrors from $mirrorlist..."
echo ""

# mingw-w64-ucrt-x86_64-OpenSceneGraph-debug-3.6.5-25-any.pkg.tar.zst 160MB
# mingw-w64-ucrt-x86_64-arm-none-eabi-gcc-13.3.0-1-any.pkg.tar.zst 210MB
# mingw-w64-ucrt-x86_64-llvm-18.1.8-1-any.pkg.tar.zst 65MB

pkg_name="mingw-w64-ucrt-x86_64-arm-none-eabi-gcc-13.3.0-1-any.pkg.tar.zst"

echo "Test package: $pkg_name"
echo ""

# 배열 선언
declare -A mirror_speeds

for url in $mirror_urls; do
    echo "Testing $url/ucrt64/..."
    
    # curl을 사용하여 응답 속도 측정
    speed=$(curl -o /dev/null -s -w "%{speed_download}" --max-time 10 "$url/ucrt64/$pkg_name")
    
    # 속도를 MB/sec로 변환하여 배열에 저장
    mirror_speeds["$url"]=$(echo "$speed / 1048576" | bc -l)
    
    # 소수점 아래 6자리까지 출력(00.000000)
    printf "Download Speed: %09.6f MB/sec\n" "${mirror_speeds["$url"]}"
    echo ""
done

# 속도를 기준으로 정렬하여 상위 5개의 서버 출력
echo "Sort fastest mirrors:"
sorted_mirrors=$(for url in "${!mirror_speeds[@]}"; do
        printf "%09.6f MB/sec %s\n" "${mirror_speeds[$url]}" "$url"
done | sort -rn | tee /dev/tty)

# 서버 주소만 추출하여 배열에 저장
all_mirrors=($(echo "$sorted_mirrors" | awk '{print $3}'))

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
