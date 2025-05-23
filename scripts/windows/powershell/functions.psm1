#region PInvoke Helper Function for Broadcasting Environment Change
# 이 함수는 내부적으로 사용되며, 직접 Export하지 않습니다.
# 스크립트/모듈 로드 시 한 번 타입 로드를 시도하고, 이후에는 캐시된 타입을 사용합니다.
function Invoke-BroadcastEnvironmentChange {
    [CmdletBinding()]
    param()

    Write-Verbose "Attempting to broadcast environment change to the system."

    # SendMessageTimeout P/Invoke 시그니처 정의 (한 번만 로드되도록 관리)
    if (-not $global:__SendMessageTimeoutType__) {
        $signature = @"
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd,
    uint Msg,
    UIntPtr wParam,
    string lParam,
    uint fuFlags,
    uint uTimeout,
    out UIntPtr lpdwResult);
"@
        try {
            # -PassThru를 사용하여 생성된 타입을 전역 변수에 저장
            # 클래스 이름은 유효한 C# 식별자로, 네임스페이스는 원하는 구조로 지정
            $global:__SendMessageTimeoutType__ = Add-Type -MemberDefinition $signature -Name "PInvokeHelper" -Namespace "MyModule.Win32" -PassThru -ErrorAction Stop
            Write-Verbose "SendMessageTimeout P/Invoke type ([MyModule.Win32.PInvokeHelper]) loaded."
        } catch {
            # 오류 메시지에 컴파일러 오류 세부 정보 포함
            $errorMessage = "Failed to load P/Invoke type for SendMessageTimeout: $($_.Exception.Message)"
            if ($_.Exception.ErrorRecord -and $_.Exception.ErrorRecord.ErrorDetails) {
                $errorMessage += " Details: $($_.Exception.ErrorRecord.ErrorDetails.Message)"
            }
            Write-Warning $errorMessage
            Write-Warning "Environment variable changes might not be broadcasted immediately to other applications."
            $global:__SendMessageTimeoutType__ = $null # 로드 실패 시 null로 설정
            return
        }
    } elseif ($null -eq $global:__SendMessageTimeoutType__) {
        # 이전에 로드 시도했으나 실패한 경우
        Write-Verbose "P/Invoke type for SendMessageTimeout was previously not loaded successfully. Skipping broadcast."
        return
    } else {
        Write-Verbose "SendMessageTimeout P/Invoke type ([MyModule.Win32.PInvokeHelper]) already loaded."
    }

    # 실제 브로드캐스트 로직
    $HWND_BROADCAST = [System.IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x1A
    $TIMEOUT_MS = 5000 # 5초
    $broadcastLParam = "Environment" # 변경된 설정이 환경 변수임을 알림

    Write-Host "Broadcasting environment variable change to the system..."
    $result = [System.UIntPtr]::Zero
    # SMTO_ABORTIFHUNG (0x0002), SMTO_NOTIMEOUTIFNOTHUNG (0x0008) 사용 가능
    # $global:__SendMessageTimeoutType__은 [MyModule.Win32.PInvokeHelper] 타입 객체를 참조
    $broadcastResult = $global:__SendMessageTimeoutType__::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [System.UIntPtr]::Zero, $broadcastLParam, 0x0002, $TIMEOUT_MS, [ref]$result)

    if ($broadcastResult -eq [System.IntPtr]::Zero) {
        $lastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        if ($lastError -ne 0) { # 0은 ERROR_SUCCESS
            Write-Warning "SendMessageTimeout call failed. Win32 Error Code: $lastError. Changes might not be immediately effective for all applications."
        } else {
            # 반환값이 0이지만 GetLastError도 0이면, 타임아웃 등의 이유일 수 있음.
            # SendMessageTimeout은 성공 시 0이 아닌 값을 반환해야 함. 0 반환은 실패로 간주.
            Write-Warning "SendMessageTimeout call returned 0, indicating failure (possibly timed out or some windows didn't respond). Win32 Error Code: $lastError."
        }
    } else {
        Write-Verbose "SendMessageTimeout call successful. (Return: $broadcastResult, Result param: $result)"
        Write-Host "Broadcast message sent successfully."
    }
    Write-Host "Changes should be reflected in new processes. Some applications might pick up changes immediately."
    Write-Host "A system restart or re-login might still be required for a full system-wide update in some cases."
}
#endregion

# (Add-PathToSystemEnvironment, Set-SystemEnvironmentVariable, Update-SystemPathVariable 함수들은 이전과 동일)
# ... 나머지 함수 코드 ...

function Add-PathToSystemEnvironment {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PathToAdd
    )

    Write-Verbose "Function Start: Add-PathToSystemEnvironment"
    $trimmedPathToAdd = $PathToAdd.Trim() # 입력 경로 앞뒤 공백 제거
    Write-Verbose "Input Path: $trimmedPathToAdd"

    # --- 시스템 PATH 읽기 (비확장 상태, 레지스트리 직접 접근) ---
    $rawSystemPathFromRegistry = $null
    $regKeyRead = $null
    $regPath = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    try {
        Write-Verbose "Opening registry key HKLM\$regPath for reading non-expanded Path..."
        $regKeyRead = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($regPath, $false)

        if (-not $regKeyRead) {
            throw "레지스트리 키 'HKLM\$regPath'를 읽기 모드로 열 수 없습니다. 권한을 확인하거나 키가 존재하는지 확인하세요."
        }

        Write-Verbose "Retrieving non-expanded 'Path' value from registry..."
        $rawSystemPathFromRegistry = $regKeyRead.GetValue("Path", $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

        if ($null -eq $rawSystemPathFromRegistry) {
            Write-Warning "레지스트리에서 'Path' 값을 찾을 수 없습니다. 새 값으로 생성될 예정입니다."
            $rawSystemPathFromRegistry = ""
        }
        Write-Verbose "Current non-expanded system PATH from registry: `"$rawSystemPathFromRegistry`""
    } catch {
        Write-Error "시스템 PATH 환경 변수(비확장)를 레지스트리에서 읽는 데 실패했습니다: $($_.Exception.Message)"
        return
    } finally {
        if ($null -ne $regKeyRead) {
            Write-Verbose "Closing read-only registry key handle."
            $regKeyRead.Close()
        }
    }
    # --- 시스템 PATH 읽기 완료 ---

    $pathEntriesNonExpanded = $rawSystemPathFromRegistry -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    $isAlreadyPresent = $false
    foreach ($entry in $pathEntriesNonExpanded) {
        if ($entry.Equals($trimmedPathToAdd, [System.StringComparison]::OrdinalIgnoreCase)) {
            $isAlreadyPresent = $true
            break
        }
    }

    Write-Host "확인 대상 경로: '$trimmedPathToAdd'"
    if ($isAlreadyPresent) {
        Write-Host "'$trimmedPathToAdd' 경로는 이미 시스템 PATH (비확장, 대소문자 무시)에 존재합니다."
    }
    else {
        Write-Host "'$trimmedPathToAdd' 경로가 PATH에 존재하지 않습니다. 추가를 시도합니다..."

        if ($pscmdlet.ShouldProcess("시스템 환경 변수 PATH (레지스트리 값)", "경로 '$trimmedPathToAdd' 추가")) {
            $regKey = $null
            try {
                Write-Verbose "Opening registry key HKLM\$regPath for read/write..."
                $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($regPath, $true)

                if (-not $regKey) {
                    throw "레지스트리 키 'HKLM\$regPath'를 쓰기 모드로 열 수 없습니다. 관리자 권한을 확인하세요."
                }

                Write-Verbose "Retrieving non-expanded 'Path' value for modification..."
                $originalRawPath = $regKey.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                Write-Verbose "Original non-expanded system PATH: $originalRawPath"

                # 새 PATH 값 구성 (기존 경로의 앞에 추가)
                $newPathValue = if ([string]::IsNullOrEmpty($originalRawPath)) {
                                    $trimmedPathToAdd
                                } else {
                                    $trimmedPathToAdd;$originalRawPath
                                }
                Write-Verbose "Constructed new PATH value: $newPathValue"

                Write-Host "새로운 PATH 값 (비확장): $newPathValue"

                Write-Verbose "Setting 'Path' value in registry as REG_EXPAND_SZ..."
                $regKey.SetValue("Path", $newPathValue, [Microsoft.Win32.RegistryValueKind]::ExpandString)
                Write-Host "시스템 PATH가 레지스트리에 성공적으로 업데이트되었습니다."

                # 시스템에 변경 사항 알림
                Invoke-BroadcastEnvironmentChange

                # 현재 PowerShell 세션의 PATH 업데이트 (선택 사항, 필요한 경우)
                Update-SystemPathVariable
                Write-Verbose "Current PowerShell session PATH updated."

            } catch {
                Write-Error "시스템 PATH 업데이트 중 오류 발생: $($_.Exception.Message)"
            } finally {
                if ($null -ne $regKey) {
                    Write-Verbose "Closing writable registry key handle."
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
        [ValidateSet("String", "ExpandString", "Binary", "DWord", "MultiString", "QWord", "Unknown")]
        [string]$PropertyType 
    )

    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    Write-Verbose "Function Start: Set-SystemEnvironmentVariable"
    Write-Verbose "Variable: '$VariableName', Value: '$VariableValue', Type: '$PropertyType'"

    if ($PSCmdlet.ShouldProcess("시스템 환경 변수 '$VariableName' (레지스트리)", "값 '$VariableValue' (타입: $PropertyType) 설정")) {
        try {
            Write-Verbose "Setting system environment variable '$VariableName' in registry path '$regPath'..."
            New-ItemProperty -Path $regPath `
                             -Name $VariableName `
                             -Value $VariableValue `
                             -PropertyType $PropertyType `
                             -Force -ErrorAction Stop

            Write-Host "시스템 환경 변수 '$VariableName'이(가) 성공적으로 설정/업데이트되었습니다."

            # 시스템에 변경 사항 알림
            Invoke-BroadcastEnvironmentChange

            if ($VariableName -ne "Path") { 
                Write-Verbose "Updating current PowerShell session's environment variable '$VariableName'..."
                Set-Content "env:\$VariableName" -Value $VariableValue
            } else {
                Update-SystemPathVariable
            }
            Write-Verbose "Current PowerShell session environment updated for '$VariableName'."

        } catch {
            Write-Error "시스템 환경 변수 '$VariableName' 설정 실패: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "사용자 요청 또는 WhatIf 플래그로 인해 시스템 환경 변수 '$VariableName' 변경이 취소되었습니다."
    }
    Write-Verbose "Function End: Set-SystemEnvironmentVariable"
    Write-Host ""
}

function Update-SystemPathVariable {
    [CmdletBinding()]
    param()
    Write-Verbose "Function Start: Update-SystemPathVariable (for current session)"
    $systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

    $newEnvPath = ""
    if (-not [string]::IsNullOrEmpty($systemPath)) {
        $newEnvPath += $systemPath
    }
    if (-not [string]::IsNullOrEmpty($userPath)) {
        if (-not [string]::IsNullOrEmpty($newEnvPath) -and -not $newEnvPath.EndsWith(";")) {
            $newEnvPath += ";"
        }
        $newEnvPath += $userPath
    }

    $env:PATH = ($newEnvPath -replace ';{2,}', ';').Trim(';')

    Write-Host "Current PowerShell session's PATH has been refreshed from System and User PATH variables."
    Write-Verbose "New session PATH: $env:PATH"
    Write-Verbose "Function End: Update-SystemPathVariable"
}

Export-ModuleMember -Function Add-PathToSystemEnvironment, Set-SystemEnvironmentVariable, Update-SystemPathVariable
