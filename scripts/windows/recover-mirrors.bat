@echo off
chcp 65001
setlocal

SET "CURRENT_DIR=%~dp0"

echo 미러리스트를 기본값으로 복원...
"%MSYS2_PATH%\usr\bin\bash.exe" -lc "cd '%CURRENT_DIR%' && ./bash/recover-mirrors.sh"
echo 완료

endlocal
pause
