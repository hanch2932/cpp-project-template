[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 관리자 권한으로 실행되었는지 확인하고, 그렇지 않으면 관리자 권한으로 재실행
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "관리자 권한으로 실행 중이 아닙니다. 관리자 권한으로 재실행합니다."
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# $env:PSModulePath = "$env:PSModulePath;$PSScriptRoot"

Import-Module -Name $PSScriptRoot\functions.psm1

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

# MSYS2 설치
& $PSScriptRoot\install-msys2.ps1

# 윈도우 터미널 프로필에 MSYS2 관련 셸 추가
# & $PSScriptRoot\add-wt-profiles.ps1

$MSYS2_ROOT = "C:\msys64"

# MSYS2_ROOT 및 MSYS2_PATH 환경 변수 설정 (시스템 변수로 설정)
Set-SystemEnvironmentVariable -VariableName "MSYS2_ROOT" -VariableValue "$MSYS2_ROOT" -PropertyType String
Set-SystemEnvironmentVariable -VariableName "MSYS2_PATH" -VariableValue "%MSYS2_ROOT%\home\%USERNAME%\python-venv\bin;%MSYS2_ROOT%\ucrt64\bin;%MSYS2_ROOT%\usr\bin" -PropertyType ExpandString
Add-PathToSystemEnvironment -PathToAdd "%MSYS2_PATH%"

$bashPath = "$MSYS2_ROOT\usr\bin\bash.exe"

Write-Host "MSYS2 초기 설정을 시작합니다."
& $bashPath -lc "cd '$PSScriptRoot'; ../bash/setup-pacman.sh"
& $bashPath -lc "cd '$PSScriptRoot'; ../bash/update-packages.sh"
& $bashPath -lc "cd '$PSScriptRoot'; ../bash/update-packages.sh"
& $bashPath -lc "cd '$PSScriptRoot'; ../bash/install-deps.sh"
& $bashPath -lc "cd '$PSScriptRoot'; ../bash/setup-python.sh"
Write-Host "MSYS2 초기 설정이 모두 완료되었습니다."
Write-Host ""

# VSCode 확장 설치
Write-Host "VSCode 확장 설치 중..."
& code --install-extension ms-vscode.cpptools-extension-pack
& code --install-extension llvm-vs-code-extensions.vscode-clangd
& code --install-extension ms-python.python
Write-Host "설치 완료"
Write-Host ""

Write-Host "모든 개발환경 설정이 완료되었습니다."
Write-Host "컴퓨터를 재시작 하십시오."
Write-Host ""
