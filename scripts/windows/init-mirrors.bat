@echo off
chcp 65001
setlocal

SET "CURRENT_DIR=%~dp0"

echo 미러리스트를 초기값으로 변경...
"%MSYS2_PATH%\usr\bin\bash.exe" -lc "cd '%CURRENT_DIR%' && ./bash/init-mirrors.sh"
echo 완료

endlocal
pause
