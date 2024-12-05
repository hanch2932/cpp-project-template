@echo off
chcp 65001
setlocal

SET "CURRENT_DIR=%~dp0"

echo 미러리스트를 가장 빠른 순으로 정렬...
echo 이 작업은 5분정도 소요됩니다. 잠시만 기다려주세요...
"%MSYS2_PATH%\usr\bin\bash.exe" -lc "cd '%CURRENT_DIR%' && ./bash/rank-mirrors.sh"
echo 완료

endlocal
pause
