@echo off
chcp 65001
setlocal

:: 시스템 업데이트 실행
echo MSYS2 업데이트 중...
"%MSYS2_PATH%\usr\bin\bash.exe" -lc "pacman -Syu --noconfirm"
echo.
echo 추가 업데이트 확인 중...
"%MSYS2_PATH%\usr\bin\bash.exe" -lc "pacman -Syu --noconfirm"
echo.
echo MSYS2 패키지 업데이트가 완료되었습니다.

endlocal
pause
