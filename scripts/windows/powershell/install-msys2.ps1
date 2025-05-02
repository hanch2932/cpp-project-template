[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# MSYS2 최신 설치 파일 URL
$gitTag = "2025-02-21" # 버전 업데이트 시 직접 변경 필요
$cleanTag = $gitTag -replace "-", ""
$MSYS2_URL = "https://github.com/msys2/msys2-installer/releases/download/$gitTag/msys2-x86_64-$cleanTag.exe"

# MSYS2 설치 경로 설정
$MSYS2_ROOT = "C:\msys64"

# MSYS2 설치 파일 다운로드
Write-Host "다운로드 중: $MSYS2_URL"
Invoke-WebRequest -Uri $MSYS2_URL -OutFile "msys2-installer.exe"
Write-Host "MSYS2 설치 파일 다운로드 완료"

# MSYS2 설치 실행
Write-Host "MSYS2 설치 중..."
& ".\msys2-installer.exe" in --confirm-command --accept-messages --root $MSYS2_ROOT
Write-Host "MSYS2 설치 완료"

# MSYS2 설치 파일 삭제
Remove-Item "msys2-installer.exe"
Write-Host "MSYS2 설치 파일 삭제 완료"
Write-Host ""
