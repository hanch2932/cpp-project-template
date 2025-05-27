@echo off
chcp 65001
setlocal

openfiles >nul 2>&1
if not %errorlevel% == 0 (
    echo 관리자 권한이 필요합니다. 관리자 권한으로 다시 실행합니다...

    :: Windows Terminal이 있는지 확인
    set "WT_PATH="
    for /f "delims=" %%i in ('where wt 2^>nul') do set "WT_PATH=%%i"

    if defined WT_PATH (
        :: Windows Terminal이 있으면 wt 사용
        powershell -Command "Start-Process wt -ArgumentList 'cmd /c %~dpnx0' -Verb RunAs"
    ) else (
        :: Windows Terminal이 없으면 cmd 사용
        echo Windows Terminal이 존재하지 않습니다.
        powershell -Command "Start-Process cmd -ArgumentList '/c %~dpnx0' -Verb RunAs"
    )

    exit /b
)

echo.
echo 이 작업은 최초 실행 시 10분 정도 소요됩니다.
echo 인터넷 상태에 따라 소요 시간이 달라질 수 있습니다.
echo 작업이 완료될 때까지 기다려 주세요...
"C:\Windows\System32\timeout" /t 5 /nobreak > nul
echo.

echo 개발에 필요한 윈도우 프로그램 설치...
echo (1/3) PowerShell 설치 중...
winget install --accept-package-agreements --accept-source-agreements -e --id Microsoft.PowerShell
echo.
echo (2/3) VSCode 설치 중...
winget install --accept-package-agreements --accept-source-agreements -e --id Microsoft.VisualStudioCode
echo.
echo (3/3) Python 설치 중...
winget install --accept-package-agreements --accept-source-agreements -e --id Python.Python.3.13
echo 프로그램 설치 완료
echo.

echo 이 세션의 PATH 변수 갱신 중...

:: 시스템 PATH 변수 가져오기
for /f "delims=" %%A in ('powershell -Command "[System.Environment]::GetEnvironmentVariable('Path', 'Machine')"') do set SYSTEM_PATH=%%A

:: 사용자 PATH 변수 가져오기
for /f "delims=" %%A in ('powershell -Command "[System.Environment]::GetEnvironmentVariable('Path', 'User')"') do set USER_PATH=%%A

:: 시스템 PATH와 사용자 PATH 합치기
set "PATH=%SYSTEM_PATH%;%USER_PATH%"

:: 빈 경로 방지(세미콜론 두 개)
set "PATH=%PATH:;;=;%"

:: 맨 앞과 뒤에 세미콜론 제거
if "%PATH:~0,1%"==";" set "PATH=%PATH:~1%"
if "%PATH:~-1%"==";" set "PATH=%PATH:~0,-1%"

echo 변경된 PATH:
echo %PATH%
echo PATH 갱신 완료
echo.

SET "CURRENT_DIR=%~dp0"

pwsh -NoProfile -ExecutionPolicy Bypass -File "%CURRENT_DIR%\powershell\setup.ps1"

endlocal
pause
