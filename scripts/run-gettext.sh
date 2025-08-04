#!/bin/bash

# 스크립트가 실패하면 종료
set -e

echo $(pwd)

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

ROOT_DIR="$SCRIPT_DIR/.."

# 소스 파일/디렉토리 및 도메인 설정
declare -A DOMAIN_FILES=(
    ["domain1"]="
        $ROOT_DIR/path/to/source
    "
    ["domain2"]="
        $ROOT_DIR/path/to/source
    "
    ["domain3"]="
        $ROOT_DIR/path/to/source
    "
    ["domain4"]="
        $ROOT_DIR/path/to/source
    "
)

LOCALE_DIR="$ROOT_DIR/locales"  # 번역 파일 저장 디렉토리
LANGUAGES=("ko_KR" "en_US")  # 지원 언어 목록

# Step 1: POT 파일 생성
echo "Step 1: Generating POT files for each domain"
mkdir -p $LOCALE_DIR
mkdir -p $LOCALE_DIR/templates

for domain in "${!DOMAIN_FILES[@]}"; do
    SRC_FILES="${DOMAIN_FILES[$domain]}"
    POT_FILE="$LOCALE_DIR/templates/$domain.pot"

    EXIST_FILES=""
    for SRC_FILE in $SRC_FILES; do
        if [ ! -f $SRC_FILE ]; then
            echo "Skipping: $SRC_FILE does not exist."
            continue
        fi
        EXIST_FILES="$EXIST_FILES $SRC_FILE"
    done

    if [[ -z "${EXIST_FILES// }" ]]; then
        echo "Skipping generate $POT_FILE: Source files does not exist."
        continue
    fi

    echo "Generating POT file for domain '$domain' from source files:"
    for SRC_FILE in $EXIST_FILES; do
        echo " - $SRC_FILE"
    done
    xgettext $EXIST_FILES -o $POT_FILE --from-code=UTF-8 --keyword=_ --no-location
done

echo ""

# Step 2: PO 파일 생성 또는 업데이트
echo "Step 2: Generating or Updating PO files for each domain..."
for domain in "${!DOMAIN_FILES[@]}"; do
    for lang in "${LANGUAGES[@]}"; do
        PO_DIR="$LOCALE_DIR/$lang"
        PO_FILE="$PO_DIR/$domain.po"
        POT_FILE="$LOCALE_DIR/templates/$domain.pot"
        BACKUP_DIR="$LOCALE_DIR/backup/$lang"

        if [ ! -f $POT_FILE ]; then
            echo "Skipping $domain for $lang: $POT_FILE does not exist."
            continue
        fi

        if [ -f $PO_FILE ]; then
            echo "Updating $PO_FILE..."
            mkdir -p "$BACKUP_DIR"
            cp -u "$PO_FILE" "$BACKUP_DIR/$domain.po"
            msgmerge --update --backup=none $PO_FILE $POT_FILE
        else
            echo "Creating $PO_FILE..."
            mkdir -p "$PO_DIR"
            msginit --input=$POT_FILE --locale=$lang --output=$PO_FILE --no-translator
            msgconv --to-code=UTF-8 -o $PO_FILE $PO_FILE
        fi
    done
done

echo ""

# Step 3: MO 파일 생성
echo "Step 3: Generating MO files for each domain..."
for domain in "${!DOMAIN_FILES[@]}"; do
    for lang in "${LANGUAGES[@]}"; do
        MO_DIR="$LOCALE_DIR/$lang/LC_MESSAGES"
        MO_FILE="$MO_DIR/$domain.mo"
        PO_FILE="$LOCALE_DIR/$lang/$domain.po"
        mkdir -p "$MO_DIR"
        if [ ! -f $PO_FILE ]; then
            echo "Skipping $domain for $lang: $PO_FILE does not exist."
            continue
        fi
        msgfmt -o $MO_FILE $PO_FILE
        echo "Generated $MO_DIR/$domain.mo"
    done
done

echo "Translation process completed successfully."

echo ""
