function Add-PathToSystemEnvironment {
    [CmdletBinding(SupportsShouldProcess=$true)]
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

                Update-SystemPathVariable

                Write-Host "시스템 PATH가 성공적으로 업데이트되었습니다."
                Write-Host "참고: 변경 사항은 새 프로세스 또는 시스템 재시작 시 적용됩니다."

            } catch {
                # 레지스트리 작업 중 오류 처리
                Write-Error "시스템 PATH 업데이트 중 오류 발생: $($_.Exception.Message)"
            } finally {
                # *** 중요: 레지스트리 핸들 닫기 ***
                if ($null -ne $regKey) {
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

function Set-SystemEnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$VariableName,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$VariableValue,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$PropertyType
    )

    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

    Write-Host "Checking system environment variable '$VariableName'..."

    $targetScope = [System.EnvironmentVariableTarget]::Machine
    $existingValue = [System.Environment]::GetEnvironmentVariable($VariableName, $targetScope)

    if ($existingValue -ne $null) {
        Write-Host "'$VariableName' variable already exists in the System scope with value: '$existingValue'."
    }
    else {
        Write-Host "'$VariableName' variable does not exist in the System scope. Attempting to set..."

        # Use ShouldProcess for -WhatIf / -Confirm support
        if ($PSCmdlet.ShouldProcess("System Environment Variable '$VariableName'", "Set Value to '$VariableValue'")) {
            try {
                New-ItemProperty -Path $regPath `
                                 -Name $VariableName `
                                 -Value $VariableValue `
                                 -PropertyType $PropertyType `
                                 -Force ` # 만약 이름은 같지만 타입이 다른 값이 존재하면 덮어쓰기 시도
            }
            catch {
                Write-Error "Failed to set system environment variable '$VariableName'. Error: $($_.Exception.Message)"
            }
        }
    }
    Write-Host "" # Keep the blank line for spacing as in the original script
}

function Update-SystemPathVariable {
    $SYSTEM_PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $USER_PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$SYSTEM_PATH;$USER_PATH"

    # 연속된 세미콜론을 하나로 줄임
    $env:PATH = $env:PATH -replace ';;+', ';'

    # 맨 앞이나 맨 뒤에 세미콜론이 있는지 확인하고 제거
    $env:PATH = $env:PATH.Trim(';')
}

# 만약 사용하지 않으면 기본적으로 모든 함수를 내보낸다.
Export-ModuleMember -Function Add-PathToSystemEnvironment, Set-SystemEnvironmentVariable, Update-SystemPathVariable
