[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host '윈도우 터미널 프로필 추가 중...'
# 설정 파일 경로
$settingsFilePath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# 기존 설정 읽기
if (Test-Path $settingsFilePath) {
    $settingsJson = Get-Content -Path $settingsFilePath -Raw | ConvertFrom-Json

    # 중복 확인 함수
    function ProfileExists {
        param ($profiles, $profileName)
        return $profiles | Where-Object { $_.name -eq $profileName }
    }

    # 새 GUID 생성
    $newGuid = [guid]::NewGuid()

    # 새 프로필 정의
    $newProfile = @{
        guid = "{$newGuid}"
        name = "MSYS2 UCRT64"
        commandline = "%MSYS2_ROOT%/msys2_shell.cmd -defterm -here -no-start -ucrt64"
        startingDirectory = "%MSYS2_ROOT%/home/%USERNAME%"
        icon = "%MSYS2_ROOT%/ucrt64.ico"
    }

    $newGuid2 = [guid]::NewGuid()
    $newProfile2 = @{
        guid = "{$newGuid2}"
        name = "MSYS2 MSYS"
        commandline = "%MSYS2_ROOT%/msys2_shell.cmd -defterm -here -no-start -msys"
        startingDirectory = "%MSYS2_ROOT%/home/%USERNAME%"
        icon = "%MSYS2_ROOT%/msys2.ico"
    }

    # 중복 확인 후 추가
    if (-not (ProfileExists -profiles $settingsJson.profiles.list -profileName $newProfile.name)) {
        $settingsJson.profiles.list += $newProfile
        Write-Host "프로필 'MSYS2 UCRT64' 추가됨."
    } else {
        Write-Host "프로필 'MSYS2 UCRT64'은 이미 존재합니다."
    }

    if (-not (ProfileExists -profiles $settingsJson.profiles.list -profileName $newProfile2.name)) {
        $settingsJson.profiles.list += $newProfile2
        Write-Host "프로필 'MSYS2 MSYS' 추가됨."
    } else {
        Write-Host "프로필 'MSYS2 MSYS'은 이미 존재합니다."
    }

    # JSON으로 변환 후 저장
    $settingsJson | ConvertTo-Json -Depth 32 | Set-Content -Path $settingsFilePath -Encoding UTF8
    Write-Host '완료'
} else {
    Write-Host "Settings.json 파일을 찾을 수 없습니다."
    exit
}
Write-Host ''
