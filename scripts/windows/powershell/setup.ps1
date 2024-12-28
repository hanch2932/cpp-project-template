[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 관리자 권한으로 실행되었는지 확인하고, 그렇지 않으면 관리자 권한으로 재실행
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "관리자 권한으로 실행 중이 아닙니다. 관리자 권한으로 재실행합니다."
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# PowerShell 실행 정책을 RemoteSigned로 변경
Write-Host "PowerShell 실행 정책을 RemoteSigned로 변경..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

& powershell Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
& powershell Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
& powershell Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
Write-Host "변경 완료"
Write-Host ""

# PowerShell을 UTF-8 인코딩으로 변경
Write-Host "PowerShell 프로필에 utf-8 인코딩 추가..."
$profilePath = $PROFILE
if (-not (Test-Path -Path $profilePath)) { 
    New-Item -ItemType File -Path $profilePath -Force 
}
$content = Get-Content -Path $profilePath
if ($content -notcontains "[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8") { 
    Add-Content -Path $profilePath -Value "[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8"
    Write-Output "PowerShell 프로필에 [System.Console]::OutputEncoding 설정이 추가되었습니다."
}
else { 
    Write-Output "설정이 이미 존재합니다."
}
Write-Host ""

# MSYS2 최신 설치 파일 URL
$gitTag = "2024-11-16" # 버전 업데이트 시 직접 변경 필요
$cleanTag = $gitTag -replace "-", ""
$MSYS2_URL = "https://github.com/msys2/msys2-installer/releases/download/$gitTag/msys2-x86_64-$cleanTag.exe"

# MSYS2 설치 경로 설정
$MSYS2_DIR = "C:\msys64"

# MSYS2 설치 경로가 존재하는지 확인
if (Test-Path -Path $MSYS2_DIR) {
    Write-Host "MSYS2가 이미 설치되어 있습니다: $MSYS2_DIR"
} else {
    # MSYS2 설치 파일 다운로드
    Write-Host "다운로드 중: $MSYS2_URL"
    Invoke-WebRequest -Uri $MSYS2_URL -OutFile "msys2-installer.exe"
    Write-Host "MSYS2 설치 파일 다운로드 완료"

    # MSYS2 설치 실행
    Write-Host "MSYS2 설치 중..."
    & ".\msys2-installer.exe" in --confirm-command --accept-messages --root $MSYS2_DIR
    Write-Host "MSYS2 설치 완료"

    # MSYS2 설치 파일 삭제
    Remove-Item "msys2-installer.exe"
    Write-Host "MSYS2 설치 파일 삭제 완료"
}
Write-Host ""

# 현재 시스템 PATH 가져오기(경로에 포함된 환경변수를 치환해서 가져온다.)
$CURRENT_PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

# 추가할 경로 설정
$NEW_PATH = "$MSYS2_DIR\usr\bin"
$NEW_PATH2 = "$MSYS2_DIR\ucrt64\bin"

# ucrt64/bin 디렉토리가 PATH에 존재하는지 확인
Write-Host "기존 PATH:"
Write-Host $CURRENT_PATH
Write-Host ""
Write-Host "추가할 PATH:"
Write-Host "$NEW_PATH2;$NEW_PATH"
Write-Host ""

# NEW_PATH 경로가 시스템 PATH에 존재하는지 확인
Write-Host "$NEW_PATH 경로가 시스템 PATH에 존재하는지 확인합니다..."
if ($CURRENT_PATH -split ";" -contains $NEW_PATH) {
    Write-Host "$NEW_PATH 경로가 이미 PATH에 존재합니다."
}
else {
    Write-Host "$NEW_PATH 경로가 PATH에 존재하지 않습니다. $NEW_PATH 경로를 추가합니다..."
    
    # 경로에 포함되어 있는 환경변수를 치환하지 않고 그대로 가져오기
    $REG_PATH = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    $REG_KEY = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($REG_PATH, $true)
    $ORIGINAL_PATH = $REG_KEY.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

    # 레지스트리에 값을 저장할 때 경로에 포함된 환경변수 인식을 위해 ExpandString 타입으로 저장해야 한다.

    # 방법 1
    $REG_SYSTEM_PATH = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    Remove-ItemProperty -Path $REG_SYSTEM_PATH -Name "Path"
    New-ItemProperty -Path $REG_SYSTEM_PATH -Name "Path" -Value "$NEW_PATH;$ORIGINAL_PATH" -PropertyType ExpandString

    # 방법 2
    # $REG_KEY.SetValue("Path", "$NEW_PATH;$ORIGINAL_PATH", [Microsoft.Win32.RegistryValueKind]::ExpandString)

    Write-Host "시스템 PATH가 성공적으로 업데이트되었습니다."
}
Write-Host ""

$CURRENT_PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

# NEW_PATH2 경로가 시스템 PATH에 존재하는지 확인
Write-Host "$NEW_PATH2 경로가 시스템 PATH에 존재하는지 확인합니다..."
if ($CURRENT_PATH -split ";" -contains $NEW_PATH2) {
    Write-Host "$NEW_PATH2 경로가 이미 PATH에 존재합니다."
}
else {
    Write-Host "$NEW_PATH2 경로가 PATH에 존재하지 않습니다. $NEW_PATH2 경로를 추가합니다..."

    # 경로에 포함되어 있는 환경변수를 치환하지 않고 그대로 가져오기
    $REG_PATH = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    $REG_KEY = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($REG_PATH, $true)
    $ORIGINAL_PATH = $REG_KEY.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

    # 레지스트리에 값을 저장할 때 경로에 포함된 환경변수 인식을 위해 ExpandString 타입으로 저장해야 한다.

    # 방법 1
    $REG_SYSTEM_PATH = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    Remove-ItemProperty -Path $REG_SYSTEM_PATH -Name "Path"
    New-ItemProperty -Path $REG_SYSTEM_PATH -Name "Path" -Value "$NEW_PATH2;$ORIGINAL_PATH" -PropertyType ExpandString

    # 방법 2
    # $REG_KEY.SetValue("Path", "$NEW_PATH2;$ORIGINAL_PATH", [Microsoft.Win32.RegistryValueKind]::ExpandString)

    Write-Host "시스템 PATH가 성공적으로 업데이트되었습니다."
}
Write-Host ""

# MSYS2_PATH 환경 변수 설정 (시스템 변수로 설정)
Write-Host "MSYS2_PATH 변수 설정을 확인합니다..."
if ([System.Environment]::GetEnvironmentVariable("MSYS2_PATH", "Machine")) {
    Write-Host "MSYS2_PATH 변수가 이미 설정되어 있습니다."
}
else {
    Write-Host "MSYS2_PATH 변수가 설정되지 않았습니다. 새로 설정합니다."
    [System.Environment]::SetEnvironmentVariable("MSYS2_PATH", $MSYS2_DIR, "Machine")
    Write-Host "MSYS2_PATH 설정 완료"
}
Write-Host ""

Write-Host "이 세션의 PATH 변수 갱신 중..."
$SYSTEM_PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
$USER_PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$env:PATH = "$SYSTEM_PATH;$USER_PATH"

# 연속된 세미콜론을 하나로 줄임
$env:PATH = $env:PATH -replace ';;+', ';'

# 맨 앞이나 맨 뒤에 세미콜론이 있는지 확인하고 제거
$env:PATH = $env:PATH.Trim(';')

Write-Host "$env:Path"
Write-Host "완료"
Write-Host ""

$bashPath = "$MSYS2_DIR\usr\bin\bash.exe"

Write-Host "MSYS2 초기 설정 중..."
# /etc/pacman.conf 설정 값 수정
& $bashPath -lc "sed -i 's/^#\?\s*ParallelDownloads\s*=.*/ParallelDownloads = 10/' /etc/pacman.conf"
& $bashPath -lc "sed -i 's/^\s*CheckSpace/#&/' /etc/pacman.conf"
& $bashPath -lc "sed -i 's/^#\?\s*VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf"
Write-Host "완료"
Write-Host ""

Write-Host "미리 정렬된 미러리스트 적용..."
& $bashPath -lc "cd '$PSScriptRoot'; ../bash/init-mirrors.sh"
Write-Host "완료"
Write-Host ""

# 시스템 업데이트 실행
Write-Host "MSYS2 시스템 업데이트 중..."
& $bashPath -lc "pacman -Syu --noconfirm"
Write-Host "MSYS2 시스템 업데이트 완료"
Write-Host ""

# 나머지 패키지 업데이트
Write-Host "나머지 패키지 업데이트 중..."
& $bashPath -lc "pacman -Syu --noconfirm"
Write-Host "패키지 업데이트 완료"
Write-Host ""

# 개발 환경 관련 패키지 설치
Write-Host "프로젝트 개발환경 관련 패키지 설치 중..."
& $bashPath -lc "pacman -Sy --noconfirm --needed \
                            base-devel \
                            bc \
                            mingw-w64-ucrt-x86_64-toolchain \
                            mingw-w64-ucrt-x86_64-clang \
                            mingw-w64-ucrt-x86_64-clang-tools-extra \
                            mingw-w64-ucrt-x86_64-ninja \
                            mingw-w64-ucrt-x86_64-cmake \
                            mingw-w64-ucrt-x86_64-gettext-tools \
                            mingw-w64-ucrt-x86_64-doxygen \
                            mingw-w64-ucrt-x86_64-python-pip"
Write-Host "패키지 설치 완료"
Write-Host ""

Write-Host 'Python 초기 설정 중...'
& $bashPath -lc '/ucrt64/bin/python -m venv ~/python'
& $bashPath -lc 'grep -qxF "export PATH=\"\$HOME/python/bin:\$PATH\"" /etc/profile || echo "export PATH=\"\$HOME/python/bin:\$PATH\"" >> /etc/profile'
Write-Host '완료'
Write-Host ''

$PYTHON_PATH = "$MSYS2_DIR\home\$env:USERNAME\python\bin"
$CURRENT_PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

# PYTHON_PATH 경로가 시스템 PATH에 존재하는지 확인
Write-Host "$PYTHON_PATH 경로가 시스템 PATH에 존재하는지 확인합니다..."
if ($CURRENT_PATH -split ";" -contains $PYTHON_PATH) {
    Write-Host "$PYTHON_PATH 경로가 이미 PATH에 존재합니다."
}
else {
    Write-Host "$PYTHON_PATH 경로가 PATH에 존재하지 않습니다. $PYTHON_PATH 경로를 추가합니다..."

    # 경로에 포함되어 있는 환경변수를 치환하지 않고 그대로 가져오기
    $REG_PATH = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    $REG_KEY = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($REG_PATH, $true)
    $ORIGINAL_PATH = $REG_KEY.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

    # 레지스트리에 값을 저장할 때 경로에 포함된 환경변수 인식을 위해 ExpandString 타입으로 저장해야 한다.

    # 방법 1
    $REG_SYSTEM_PATH = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    Remove-ItemProperty -Path $REG_SYSTEM_PATH -Name "Path"
    New-ItemProperty -Path $REG_SYSTEM_PATH -Name "Path" -Value "$PYTHON_PATH;$ORIGINAL_PATH" -PropertyType ExpandString

    # 방법 2
    # $REG_KEY.SetValue("Path", "$NEW_PATH2;$ORIGINAL_PATH", [Microsoft.Win32.RegistryValueKind]::ExpandString)

    Write-Host "시스템 PATH가 성공적으로 업데이트되었습니다."
}
Write-Host ""

Write-Host "이 세션의 PATH 변수 갱신 중..."
$SYSTEM_PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
$USER_PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$env:PATH = "$SYSTEM_PATH;$USER_PATH"

# 연속된 세미콜론을 하나로 줄임
$env:PATH = $env:PATH -replace ';;+', ';'

# 맨 앞이나 맨 뒤에 세미콜론이 있는지 확인하고 제거
$env:PATH = $env:PATH.Trim(';')

Write-Host "$env:Path"
Write-Host "완료"
Write-Host ""

# Python 패키지 설치
Write-Host "Python 패키지 설치 중..."
& python -m pip install --upgrade pip
Write-Host ""
& pip install mkdocs mkdocs-material mkdoxy
Write-Host "패키지 설치 완료"
Write-Host ""

# VSCode 확장 설치
Write-Host "VSCode 확장 설치 중..."
& code --install-extension ms-vscode.cpptools-extension-pack
& code --install-extension llvm-vs-code-extensions.vscode-clangd
& code --install-extension ms-python.python
Write-Host "설치 완료"
Write-Host ""

Write-Host "모든 개발환경 설정이 완료되었습니다."
Write-Host "실행 중인 VSCode를 모두 종료한 뒤 다시 실행하세요."
Write-Host ""
