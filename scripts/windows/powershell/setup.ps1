[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 관리자 권한으로 실행되었는지 확인하고, 그렇지 않으면 관리자 권한으로 재실행
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "관리자 권한으로 실행 중이 아닙니다. 관리자 권한으로 재실행합니다."
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

function Add-PathToSystemEnvironment {
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PathToAdd
    )

    Write-Verbose "Function Start: Add-PathToSystemEnvironment"
    Write-Verbose "Input Path: $PathToAdd"

    # 시스템 PATH 읽기 (확장된 상태)
    try {
        $currentSystemPathExpanded = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        Write-Verbose "Current expanded system PATH read successfully."
    } catch {
        Write-Error "시스템 PATH 환경 변수를 읽는 데 실패했습니다: $($_.Exception.Message)"
        return # 함수 실행 중단
    }

    # 경로 존재 여부 확인
    $pathEntries = $currentSystemPathExpanded -split ';' | Where-Object { $_ -ne '' }
    Write-Host "$PathToAdd 경로가 시스템 PATH에 존재하는지 확인합니다..."
    if ($pathEntries -contains $PathToAdd) {
        Write-Host "$PathToAdd 경로가 이미 PATH에 존재합니다."
    }
    else {
        Write-Host "$PathToAdd 경로가 PATH에 존재하지 않습니다. 추가를 시도합니다..."

        # WhatIf/Confirm 지원
        if ($pscmdlet.ShouldProcess("시스템 환경 변수 PATH", "경로 '$PathToAdd' 추가")) {

            $regKey = $null # 명시적 초기화
            try {
                # 레지스트리 키 열기 (읽기/쓰기)
                $regPath = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
                Write-Verbose "Opening registry key HKLM\$regPath for read/write..."
                $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($regPath, $true) # $true = 쓰기 가능

                if (-not $regKey) {
                    throw "레지스트리 키 'HKLM\$regPath'를 열 수 없습니다. 권한을 확인하세요."
                }

                # 원본 PATH 값 가져오기 (비확장)
                Write-Verbose "Retrieving non-expanded 'Path' value..."
                $originalRawPath = $regKey.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                Write-Verbose "Original non-expanded system PATH: $originalRawPath"

                # 새 PATH 값 구성
                $newPathValue = if ([string]::IsNullOrEmpty($originalRawPath)) {
                                    $PathToAdd
                                } else {
                                    "$PathToAdd;$originalRawPath"
                                }
                Write-Verbose "Constructed new PATH value: $newPathValue"

                # 레지스트리에 새 PATH 값 쓰기 (ExpandString 타입) - SetValue 사용
                Write-Verbose "Setting 'Path' value in registry using SetValue (ExpandString)..."
                $regKey.SetValue("Path", $newPathValue, [Microsoft.Win32.RegistryValueKind]::ExpandString)

                Write-Host "시스템 PATH가 성공적으로 업데이트되었습니다."
                Write-Host "참고: 변경 사항은 새 프로세스 또는 시스템 재시작 시 적용됩니다."

            } catch {
                # 레지스트리 작업 중 오류 처리
                Write-Error "시스템 PATH 업데이트 중 오류 발생: $($_.Exception.Message)"
            } finally {
                # *** 중요: 레지스트리 핸들 닫기 ***
                if ($regKey -ne $null) {
                    Write-Verbose "Closing registry key handle."
                    $regKey.Close()
                }
            }
        } else {
            Write-Warning "사용자 요청 또는 WhatIf 플래그로 인해 시스템 PATH 변경이 취소되었습니다."
        }
    }
    Write-Verbose "Function End: Add-PathToSystemEnvironment"
    Write-Host ""
}

function Renew-SystemPathVariable {
    $SYSTEM_PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $USER_PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$SYSTEM_PATH;$USER_PATH"

    # 연속된 세미콜론을 하나로 줄임
    $env:PATH = $env:PATH -replace ';;+', ';'

    # 맨 앞이나 맨 뒤에 세미콜론이 있는지 확인하고 제거
    $env:PATH = $env:PATH.Trim(';')
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
$gitTag = "2025-02-21" # 버전 업데이트 시 직접 변경 필요
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
# $CURRENT_PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

# 추가할 경로 설정
$NEW_PATH = "$MSYS2_DIR\usr\bin"
$NEW_PATH2 = "$MSYS2_DIR\ucrt64\bin"

# ucrt64/bin 디렉토리가 PATH에 존재하는지 확인
# Write-Host "기존 PATH:"
# Write-Host $CURRENT_PATH
# Write-Host ""
# Write-Host "추가할 PATH:"
# Write-Host "$NEW_PATH2;$NEW_PATH"
# Write-Host ""

Add-PathToSystemEnvironment -PathToAdd $NEW_PATH
Add-PathToSystemEnvironment -PathToAdd $NEW_PATH2

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
Renew-SystemPathVariable
Write-Host "$env:Path"
Write-Host "완료"
Write-Host ""

$bashPath = "$MSYS2_DIR\usr\bin\bash.exe"

Write-Host "MSYS2 초기 설정을 시작합니다."
& $bashPath -lc "cd '$PSScriptRoot'; ../bash/setup.sh"
Write-Host "MSYS2 초기 설정이 모두 완료되었습니다."
Write-Host ""

$PYTHON_PATH = "$MSYS2_DIR\home\$env:USERNAME\python-venv\bin"

Add-PathToSystemEnvironment -PathToAdd $PYTHON_PATH

Write-Host "이 세션의 PATH 변수 갱신 중..."
Renew-SystemPathVariable
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
