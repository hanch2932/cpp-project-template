# setup_utils.py (환경 변수 및 시스템 유틸리티 함수)

import winreg
import ctypes
import os
import sys
import subprocess  # 외부 명령 실행 (예: winget, code, bash)
import requests  # 파일 다운로드
from tqdm import tqdm  # 진행률 표시

# --- 상수 ---
# 환경 변수 변경 브로드캐스트용
HWND_BROADCAST = 0xFFFF
WM_SETTINGCHANGE = 0x001A
SMTO_ABORTIFHUNG = 0x0002
SMTO_NOTIMEOUTIFNOTHUNG = 0x0008


# --- 기본 유틸리티 ---
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False


def run_as_admin_if_needed(script_path=None, arguments=""):
    """필요시 스크립트를 관리자 권한으로 재실행합니다."""
    if not is_admin():
        print("관리자 권한이 필요합니다. 스크립트를 관리자 권한으로 다시 실행합니다...")
        if script_path is None:
            script_path = os.path.abspath(sys.argv[0])  # 현재 실행 중인 스크립트

        try:
            executable = sys.executable
            # Windows Terminal 또는 cmd를 통해 재실행
            # (이전 코드의 run_as_admin 로직을 여기에 통합하거나 유사하게 구현)
            # 간결성을 위해 여기서는 ShellExecuteW만 사용
            ctypes.windll.shell32.ShellExecuteW(
                None, "runas", executable, f'"{script_path}" {arguments}', None, 1
            )
            sys.exit(0)  # 현재 비관리자 프로세스 종료
        except Exception as e:
            print(f"관리자 권한으로 재실행 중 오류 발생: {e}")
            sys.exit(1)
    else:
        print("스크립트가 관리자 권한으로 실행 중입니다.")


def run_command_direct_output(
    command_list, success_message="", error_message="", shell=False, cwd=None, env=None
):
    """
    주어진 명령을 실행하고, 자식 프로세스가 터미널에 직접 출력하도록 합니다.
    C++ system()과 유사하게 동작합니다.
    """
    print(
        f"실행 시작: {' '.join(command_list) if isinstance(command_list, list) else command_list}"
    )

    try:
        # stdout, stderr를 None (기본값)으로 두면 부모의 스트림을 상속받음
        process = subprocess.run(
            command_list,
            shell=shell,
            cwd=cwd,
            env=env,
            check=False,  # 반환 코드 직접 확인
            # stdin=None, stdout=None, stderr=None (이것이 기본값)
        )

        if process.returncode == 0:
            if success_message:
                print(success_message)
            print(f"'{command_list[0]}' 실행 완료 (종료 코드: 0)\n")
            return True
        # else:
        #     # 오류 메시지는 여기서 출력하거나, 호출부에서 처리
        #     err_msg_to_print = (
        #         error_message
        #         if error_message
        #         else f"'{command_list[0]}' 실행 중 오류 발생"
        #     )
        #     print(f"{err_msg_to_print} (종료 코드: {process.returncode})\n")
        #     return False

    except FileNotFoundError:
        print(
            f"오류: 명령 '{command_list[0] if isinstance(command_list, list) else command_list.split()[0]}'을(를) 찾을 수 없습니다. PATH를 확인하세요.\n"
        )
        return False
    except Exception as e:
        print(f"명령 실행 중 예외 발생: {e}\n")
        return False


def run_command(
    command_list,
    success_message="",
    error_message="",
    shell=False,
    cwd=None,
    env=None,
    capture_output_for_result=False,
):  # capture_output -> capture_output_for_result
    """
    주어진 명령을 실행하고 출력을 실시간으로 스트리밍합니다.
    capture_output_for_result: True이면 stdout, stderr를 캡처하여 반환값으로 사용.
                               False이면 실시간 출력만 하고 반환값은 빈 문자열.
    """
    print(
        f"실행 중: {' '.join(command_list) if isinstance(command_list, list) else command_list}"
    )

    # stdout/stderr를 저장할 변수 (capture_output_for_result가 True일 때 사용)
    full_stdout = []
    full_stderr = []

    try:
        # Popen으로 프로세스 시작
        process = subprocess.Popen(
            command_list,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            shell=shell,
            cwd=cwd,
            env=env,
            bufsize=1,  # 라인 버퍼링 활성화 (중요)
            universal_newlines=True,  # text=True와 함께 사용, 라인 엔딩 처리
        )

        # 실시간으로 stdout, stderr 읽기
        # stdout 처리
        if process.stdout:
            for line in iter(process.stdout.readline, ""):
                line_stripped = line.strip()
                print(line_stripped)  # 실시간 출력
                sys.stdout.flush()  # 즉시 터미널에 보이도록 플러시
                if capture_output_for_result:
                    full_stdout.append(line_stripped)
            process.stdout.close()

        # stderr 처리 (stdout과 별도로 또는 stdout과 인터리빙되게 처리 가능)
        # 여기서는 stdout 먼저 다 읽고 stderr 읽지만, select 등을 사용하면 동시 처리 가능
        # 또는 stderr도 stdout과 같은 방식으로 루프를 돌릴 수 있음 (별도 스레드 또는 비동기)
        # 더 간단하게는, wait() 호출 후 남은 stderr를 읽는 방식도 있음.
        # winget 같은 경우 stderr로도 정상 진행률을 출력하므로, stdout처럼 처리.
        if process.stderr:
            for line in iter(process.stderr.readline, ""):
                line_stripped = line.strip()
                # stderr 출력을 구분하고 싶다면 print(f"STDERR: {line_stripped}")
                print(line_stripped)  # 실시간 출력 (stderr도 일반 출력처럼)
                sys.stderr.flush()
                if capture_output_for_result:
                    full_stderr.append(line_stripped)
            process.stderr.close()

        process.wait()  # 프로세스 종료 대기

        # 결과 반환 (capture_output_for_result가 True일 때)
        stdout_result = "\n".join(full_stdout) if capture_output_for_result else ""
        stderr_result = "\n".join(full_stderr) if capture_output_for_result else ""

        if process.returncode == 0:
            if success_message:
                print(success_message)
            return True, stdout_result
        else:
            err_msg_to_print = (
                error_message
                if error_message
                else f"명령 실행 중 오류 발생 (종료 코드: {process.returncode})"
            )
            print(err_msg_to_print)
            # 오류 시에는 stderr 내용을 반환하는 것이 유용할 수 있음
            return False, (
                stderr_result if stderr_result else stdout_result
            )  # 오류 시 stderr 우선 반환

    except FileNotFoundError:
        msg = f"오류: 명령 '{command_list[0] if isinstance(command_list, list) else command_list.split()[0]}'을(를) 찾을 수 없습니다. PATH를 확인하세요."
        print(msg)
        return False, "FileNotFoundError"
    except Exception as e:
        msg = f"명령 실행 중 예외 발생: {e}"
        print(msg)
        return False, str(e)


# --- 환경 변수 관련 함수 ---
def _broadcast_environment_change():
    """시스템에 환경 변수 변경 사항을 알립니다."""
    try:
        SendMessageTimeout = ctypes.windll.user32.SendMessageTimeoutW
        result = ctypes.c_size_t()  # UIntPtr in C#
        # SMTO_ABORTIFHUNG (0x0002)
        # SMTO_NORMAL (0x0000)
        # SMTO_NOTIMEOUTIFNOTHUNG (0x0008) - 권장되기도 함
        status = SendMessageTimeout(
            HWND_BROADCAST,
            WM_SETTINGCHANGE,
            0,  # wParam (사용 안 함)
            "Environment",  # lParam
            SMTO_ABORTIFHUNG | SMTO_NOTIMEOUTIFNOTHUNG,  # fuFlags
            5000,  # uTimeout (5초)
            ctypes.byref(result),  # lpdwResult
        )
        if status == 0:  # 0은 실패 (타임아웃 등), GetLastError로 추가 정보 확인 가능
            last_error = ctypes.get_last_error()
            print(
                f"경고: 환경 변수 변경 브로드캐스트 실패 (SendMessageTimeout 반환값: {status}, Win32 오류 코드: {last_error})."
            )
            print("일부 응용 프로그램은 변경 사항을 즉시 감지하지 못할 수 있습니다.")
        else:
            print("환경 변수 변경 사항이 시스템에 성공적으로 브로드캐스트되었습니다.")
    except Exception as e:
        print(f"환경 변수 브로드캐스트 중 예외 발생: {e}")


def get_env_variable(name, scope="machine"):
    """시스템 또는 사용자 환경 변수를 읽습니다 (비확장)."""
    reg_hive_map = {
        "machine": winreg.HKEY_LOCAL_MACHINE,
        "user": winreg.HKEY_CURRENT_USER,
    }
    reg_path_map = {
        "machine": r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment",
        "user": r"Environment",
    }

    if scope.lower() not in reg_hive_map:
        raise ValueError("Scope는 'machine' 또는 'user'여야 합니다.")

    try:
        with winreg.ConnectRegistry(None, reg_hive_map[scope.lower()]) as hkey_root:
            with winreg.OpenKey(
                hkey_root, reg_path_map[scope.lower()], 0, winreg.KEY_READ
            ) as key:
                value, _ = winreg.QueryValueEx(key, name)
                return value
    except FileNotFoundError:
        return None  # 변수가 존재하지 않음
    except Exception as e:
        print(f"환경 변수 '{name}'({scope}) 읽기 중 오류: {e}")
        return None


def set_system_environment_variable(var_name, var_value, var_type="REG_SZ"):
    """
    시스템 환경 변수를 영구적으로 설정/업데이트합니다.
    var_type: "REG_SZ" (문자열) 또는 "REG_EXPAND_SZ" (확장 가능한 문자열)
    """
    if not is_admin():
        print("오류: 시스템 환경 변수를 설정하려면 관리자 권한이 필요합니다.")
        return False

    reg_type_map = {
        "REG_SZ": winreg.REG_SZ,
        "REG_EXPAND_SZ": winreg.REG_EXPAND_SZ,
        # 다른 타입도 필요시 추가 가능
    }
    if var_type.upper() not in reg_type_map:
        print(
            f"오류: 지원되지 않는 레지스트리 타입 '{var_type}'. REG_SZ 또는 REG_EXPAND_SZ를 사용하세요."
        )
        return False

    key_path = r"SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
    try:
        with winreg.ConnectRegistry(None, winreg.HKEY_LOCAL_MACHINE) as hkey_root:
            with winreg.OpenKey(
                hkey_root, key_path, 0, winreg.KEY_READ | winreg.KEY_WRITE
            ) as key:
                winreg.SetValueEx(
                    key, var_name, 0, reg_type_map[var_type.upper()], var_value
                )
                print(
                    f"시스템 환경 변수 '{var_name}'을(를) '{var_value}' (타입: {var_type}) (으)로 설정했습니다."
                )

        _broadcast_environment_change()

        # 현재 프로세스의 환경 변수에도 반영 (os.environ)
        # 단, Path의 경우 복잡하므로 직접 os.environ['PATH']를 수정하는 것은 주의
        if var_name != "Path":  # Path는 별도 함수로 관리하거나, 재시작 권고
            os.environ[var_name] = var_value
        return True
    except PermissionError:
        print(f"오류: 레지스트리 '{key_path}' 접근 권한 없음. 관리자 권한 확인.")
        return False
    except Exception as e:
        print(f"시스템 환경 변수 '{var_name}' 설정 중 오류: {e}")
        return False


def add_to_system_path(path_to_add, add_expanded_string=True, add_front=False):
    r"""
    시스템 PATH 환경 변수에 경로를 영구적으로 추가합니다.
    path_to_add: 추가할 경로 문자열. 예: "C:\MyDir" 또는 "%MY_VAR%\bin"
    add_expanded_string: True이면 %VAR% 형태를 REG_EXPAND_SZ로 추가, False이면 REG_SZ.
                         파워셸 스크립트의 `%MSYS2_PATH%` 확장 문제를 고려할 때,
                         파워셸 스크립트처럼 `REG_SZ` (문자열)로 "%MSYS2_PATH%"를 추가하거나,
                         `MSYS2_PATH`의 실제 경로들을 풀어서 `REG_EXPAND_SZ`로 추가할 수 있음.
                         여기서는 파워셸 스크립트의 의도를 따라, %VAR% 형태를 PATH에 넣을 땐
                         그 문자열 자체를 넣도록 `REG_EXPAND_SZ`가 적합.
                         만약 실제 값으로 확장된 경로를 넣는다면, `path_to_add`에 확장된 값을 전달.
    """
    if not is_admin():
        print("오류: 시스템 PATH를 수정하려면 관리자 권한이 필요합니다.")
        return False

    key_path = r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    try:
        with winreg.ConnectRegistry(None, winreg.HKEY_LOCAL_MACHINE) as hkey_root:
            with winreg.OpenKey(
                hkey_root, key_path, 0, winreg.KEY_READ | winreg.KEY_WRITE
            ) as key:
                try:
                    # Path는 보통 REG_EXPAND_SZ 타입임
                    current_path_value, value_type = winreg.QueryValueEx(key, "Path")
                    if (
                        value_type != winreg.REG_EXPAND_SZ
                        and value_type != winreg.REG_SZ
                    ):
                        print(
                            f"경고: 시스템 Path의 레지스트리 타입이 예상과 다릅니다 (현재: {value_type}). REG_EXPAND_SZ로 변경될 수 있습니다."
                        )
                        # 필요시 타입을 REG_EXPAND_SZ로 강제할 수 있음
                except FileNotFoundError:
                    current_path_value = ""

                # 경로 정규화 및 중복 방지
                paths = [p.strip() for p in current_path_value.split(";") if p.strip()]

                # path_to_add가 %VAR% 형태인지, 실제 경로인지에 따라 처리
                # 여기서는 파워셸처럼 %MSYS2_PATH% 자체를 추가하는 시나리오를 가정
                # 따라서 대소문자 구분 없이 문자열 비교
                path_to_add_norm = os.path.normcase(path_to_add.strip())

                if not any(os.path.normcase(p) == path_to_add_norm for p in paths):
                    # 파워셸 스크립트는 맨 앞에 추가했었음. 동일하게 하려면:
                    # paths.insert(0, path_to_add.strip())
                    # 여기서는 맨 뒤에 추가 (일반적)
                    if add_front:
                        paths.insert(0, path_to_add.strip())
                    else:
                        paths.append(path_to_add.strip())

                    new_path_value = ";".join(paths)

                    # Path는 항상 REG_EXPAND_SZ로 설정하는 것이 안전
                    winreg.SetValueEx(
                        key, "Path", 0, winreg.REG_EXPAND_SZ, new_path_value
                    )
                    print(f"시스템 PATH에 '{path_to_add.strip()}'을(를) 추가했습니다.")
                else:
                    print(
                        f"'{path_to_add.strip()}'은(는) 이미 시스템 PATH에 존재합니다."
                    )

        _broadcast_environment_change()

        # 현재 세션의 PATH도 업데이트 시도 (os.environ)
        # 이는 복잡할 수 있으므로, 주로 새 터미널 사용 권고
        update_current_session_path_from_registry()
        return True
    except PermissionError:
        print(f"오류: 레지스트리 '{key_path}' 접근 권한 없음. 관리자 권한 확인.")
        return False
    except Exception as e:
        print(f"시스템 PATH 수정 중 오류: {e}")
        return False


def update_current_session_path_from_registry():
    """레지스트리에서 시스템 및 사용자 PATH를 읽어 현재 세션의 os.environ['PATH']를 업데이트합니다."""
    print("현재 세션의 PATH를 레지스트리 기준으로 갱신 중...")
    try:
        # 비확장 상태로 가져오면 %VAR% 형태가 그대로 유지됨
        # os.path.expandvars는 현재 세션의 환경변수를 사용하므로,
        # 레지스트리 직접 읽은 후에는 broadcast 후 새 프로세스에서 효과가 나타남
        system_path_raw = get_env_variable("Path", "machine") or ""
        user_path_raw = get_env_variable("Path", "user") or ""

        # 실제로는 시스템이 Path를 사용할 때 %VAR%를 확장함.
        # os.environ에 설정할 때는 확장된 값을 넣는 것이 일반적이나,
        # 여기서는 레지스트리와 유사하게 유지하고,
        # subprocess 등에서 환경변수 상속 시 시스템이 처리하도록 함.
        # 하지만 파이썬 내부에서 os.path.exists 등으로 사용하려면 확장 필요.

        # 가장 간단한 방법: os.getenv('PATH')를 사용하면 이미 시스템에 의해 확장된 PATH를 가져옴
        # (단, 이는 broadcast 후 새 프로세스에서 반영된 값일 수 있음)
        # 여기서는 레지스트리에서 직접 읽은 값을 바탕으로 구성

        combined_path = f"{system_path_raw};{user_path_raw}"
        # 중복 세미콜론 및 앞뒤 세미콜론 제거
        final_path_list = [p for p in combined_path.split(";") if p.strip()]
        final_path_str = ";".join(final_path_list)

        os.environ["PATH"] = final_path_str
        print(
            f"현재 세션 PATH가 레지스트리 값 기준으로 업데이트됨 (다음은 os.environ['PATH'] 값):\n{os.environ['PATH']}"
        )

    except Exception as e:
        print(f"현재 세션 PATH 갱신 중 오류: {e}")


# --- MSYS2 관련 함수 ---
def download_msys2_installer(url, dest_dir):
    """MSYS2 설치 파일을 다운로드합니다."""
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir, exist_ok=True)

    file_name = os.path.join(dest_dir, "msys2-installer.exe")

    print(f"'{url}'에서 '{file_name}'(으)로 다운로드 중...")
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        total_size = int(response.headers.get("content-length", 0))

        with open(file_name, "wb") as f, tqdm(
            desc=os.path.basename(file_name),
            total=total_size,
            unit="iB",
            unit_scale=True,
            unit_divisor=1024,
        ) as bar:
            for data in response.iter_content(chunk_size=1024 * 4):  # 4KB chunks
                size = f.write(data)
                bar.update(size)
        print("MSYS2 설치 파일 다운로드 완료.")
        return file_name
    except requests.exceptions.RequestException as e:
        print(f"MSYS2 다운로드 오류: {e}")
        return None
    except Exception as e:
        print(f"파일 쓰기 또는 기타 오류: {e}")
        return None


def install_msys2(installer_path, install_root):
    """MSYS2를 설치합니다."""
    if not installer_path or not os.path.exists(installer_path):
        print("오류: MSYS2 설치 파일을 찾을 수 없습니다.")
        return False

    print(f"MSYS2를 '{install_root}'에 설치합니다...")
    # 파워셸 스크립트의 옵션: in --confirm-command --accept-messages --root $MSYS2_ROOT
    # 이는 msys2-installer.exe 자체의 인자이므로 그대로 사용
    command = [
        installer_path,
        "in",
        "--confirm-command",
        "--accept-messages",
        "--root",
        install_root,
    ]

    success = run_command_direct_output(
        command,
        success_message="MSYS2 설치가 완료된 것 같습니다.",
        error_message="MSYS2 설치 중 오류 발생.",
    )
    if success:
        # 설치 후 파일 시스템 동기화 등을 위해 잠시 대기
        import time

        time.sleep(5)
    return success


def remove_msys2_installer(installer_path):
    if installer_path and os.path.exists(installer_path):
        try:
            os.remove(installer_path)
            print(f"MSYS2 설치 파일 '{installer_path}' 삭제 완료.")
        except Exception as e:
            print(f"MSYS2 설치 파일 삭제 중 오류: {e}")


# --- PowerShell 프로필 설정 ---
def configure_powershell_profile_utf8():
    """PowerShell 프로필에 UTF-8 인코딩 설정을 추가합니다."""
    print("PowerShell 프로필에 UTF-8 인코딩 설정 추가 시도...")
    try:
        # $PROFILE 경로 가져오기
        # 'powershell -Command "$PROFILE"' 실행
        result = subprocess.run(
            ["pwsh", "-NoProfile", "-Command", "$PROFILE"],
            capture_output=True,
            text=True,
            check=True,
            encoding="utf-8",
        )
        profile_path = result.stdout.strip()

        if not profile_path:
            print("오류: PowerShell 프로필 경로를 가져올 수 없습니다.")
            return False

        if not os.path.exists(os.path.dirname(profile_path)):
            os.makedirs(os.path.dirname(profile_path), exist_ok=True)
            print(f"프로필 디렉터리 생성: {os.path.dirname(profile_path)}")

        if not os.path.exists(profile_path):
            with open(profile_path, "w", encoding="utf-8") as f:
                f.write("")  # 빈 파일 생성
            print(f"PowerShell 프로필 파일 생성: {profile_path}")

        utf8_setting = "[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8"

        content = ""
        try:
            with open(profile_path, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception as e:  # 파일이 있지만 읽기 오류 시 (예: 인코딩 문제)
            print(
                f"경고: 기존 프로필 파일 '{profile_path}' 읽기 중 오류 ({e}). 새 내용으로 덮어쓸 수 있습니다."
            )
            # 또는 다른 인코딩으로 읽기 시도 후 UTF-8로 변환 저장하는 로직 추가 가능

        if utf8_setting not in content:
            with open(profile_path, "a", encoding="utf-8") as f:  # append mode
                f.write(
                    f"\n# Added by setup script for UTF-8 support\n{utf8_setting}\n"
                )
            print(f"PowerShell 프로필에 UTF-8 설정 추가 완료: {profile_path}")
        else:
            print("PowerShell 프로필에 UTF-8 설정이 이미 존재합니다.")
        return True

    except subprocess.CalledProcessError as e:
        print(f"PowerShell 프로필 경로 가져오기 실패: {e.stderr}")
        return False
    except Exception as e:
        print(f"PowerShell 프로필 설정 중 오류: {e}")
        return False


# --- MSYS2 Bash 스크립트 실행 ---
def run_msys2_bash_script(msys2_root, script_path_relative_to_repo, repo_root_dir):
    r"""
    MSYS2 bash를 사용하여 지정된 .sh 스크립트를 실행합니다.
    msys2_root: MSYS2 설치 경로 (예: C:\msys64)
    script_path_relative_to_repo: 저장소 루트 기준 .sh 파일 경로 (예: bash/setup-pacman.sh)
    repo_root_dir: 이 파이썬 스크립트가 있는 Git 저장소의 루트 디렉토리
    """
    bash_exe = os.path.join(msys2_root, "usr", "bin", "bash.exe")
    if not os.path.exists(bash_exe):
        print(f"오류: bash.exe를 찾을 수 없습니다: {bash_exe}")
        return False

    # .sh 스크립트의 실제 경로
    # 파워셸은 $PSScriptRoot를 사용했으나, 여기서는 repo_root_dir를 명시적으로 받음
    script_full_path_in_repo = os.path.join(repo_root_dir, script_path_relative_to_repo)
    if not os.path.exists(script_full_path_in_repo):
        print(
            f"오류: 실행할 .sh 스크립트를 찾을 수 없습니다: {script_full_path_in_repo}"
        )
        return False

    # bash -lc "cd '스크립트가 있는 디렉토리'; ./스크립트파일"
    # MSYS2 bash는 윈도우 경로를 유닉스 스타일로 변환해야 할 수 있음
    # subprocess는 내부적으로 처리해주지만, cd 대상 경로는 bash가 이해하도록.
    # 스크립트 파일이 있는 디렉토리 (MSYS2 관점)
    # 예: /c/Users/name/project/bash
    script_dir_msys_style = (
        script_full_path_in_repo.replace(os.sep, "/")
        .replace("C:", "/c", 1)
        .replace("D:", "/d", 1)
    )  # 단순 변환
    script_dir_msys_style = os.path.dirname(script_dir_msys_style)
    script_name = os.path.basename(script_full_path_in_repo)

    # command = f"cd '{script_dir_msys_style}'; ./{script_name}"
    # 파워셸에서는 ../bash/script.sh 형태로 호출. 이는 cd $PSScriptRoot 후의 상대 경로.
    # $PSScriptRoot가 파이썬에서는 repo_root_dir/powershell 이었음.
    # bash 스크립트는 repo_root_dir/bash 에 있음.
    # 파워셸에서 & $bashPath -lc "cd '$PSScriptRoot'; ../bash/setup-pacman.sh"
    # $PSScriptRoot (powershell 디렉토리) 에서 cd .. (repo 루트) 후 bash/script.sh
    # 따라서, bash의 작업 디렉토리를 repo_root_dir로 설정하고, bash/script.sh 실행

    # MSYS2 bash는 윈도우 경로를 내부적으로 잘 처리하는 편.
    # 스크립트 내에서 cd가 복잡하면, bash CWD를 설정하고 스크립트만 실행.
    # 또는 스크립트가 자신의 위치를 기준으로 동작하도록 작성되어 있다면,
    # 경로 변환 없이 윈도우 경로를 그대로 전달해도 될 수 있음.
    # 여기서는 bash 스크립트가 `cd '$PSScriptRoot'; ../bash/setup-pacman.sh` 형태로
    # `../bash/` 를 사용했으므로, bash의 초기 작업 디렉토리를 파워셸 스크립트가 있던
    # `repo_root_dir/powershell` 로 설정하거나, bash 스크립트 호출 방식을 수정해야 함.
    #
    # 파워셸의 `$PSScriptRoot`는 `setup.ps1`이 있는 `powershell` 디렉토리였음.
    # Bash 스크립트들은 이 `powershell` 디렉토리의 부모(`../`) 아래 `bash` 폴더에 있음.
    # 따라서, bash의 `cd` 명령의 기준이 되는 디렉토리를 `powershell` 디렉토리로 맞춰주면
    # 기존 bash 스크립트의 `../bash/script.sh` 호출이 유효함.
    # powershell_dir_in_repo = os.path.join(
    #     repo_root_dir, "powershell"
    # )  # 또는 이 함수 호출 시 명시

    # # bash -lc "명령어" 형태
    # # bash 스크립트의 상대 경로가 `../bash/script.sh` 이므로,
    # # bash의 현재 작업 디렉토리(cd)는 `powershell` 디렉토리가 되어야 함.
    # msys_style_powershell_dir = powershell_dir_in_repo.replace(os.sep, "/").replace(
    #     "C:", "/c", 1
    # )  # 단순 변환

    # bash 스크립트 경로 (예: ../bash/setup-pacman.sh)
    # script_path_relative_to_repo 가 "bash/setup-pacman.sh" 이므로,
    # 실제 호출은 `../` + script_path_relative_to_repo 가 되어야 함.
    # 파워셸은 `$PSScriptRoot` (powershell 폴더) 에서 `../bash/script.sh` 실행.
    # 파이썬에서 bash를 호출할 때, bash의 CWD를 `powershell` 폴더로 설정하고,
    # 그 안에서 `../bash/script.sh` 를 실행하도록 명령 구성.

    # script_path_relative_to_repo 가 "bash/script.sh" 형태이므로,
    # bash의 CWD를 repo_root_dir로 하고, "bash/script.sh"를 실행하는 것이 더 간단.
    # 이 경우 bash 스크립트 내에서 `cd '$PSScriptRoot'`는 필요 없음.
    # 여기서는 기존 bash 스크립트 구조를 최대한 유지하기 위해
    # 파워셸과 유사한 환경을 만들어줌.

    bash_command_string = f"cd '{repo_root_dir}'; {script_path_relative_to_repo}"
    # 예: script_path_relative_to_repo = "bash/setup-pacman.sh"
    # -> bash_command_string = "cd '/c/repo/powershell'; ../bash/setup-pacman.sh"

    full_bash_command = [bash_exe, "-lc", bash_command_string]

    print(f"MSYS2 Bash 스크립트 실행 시작: {' '.join(full_bash_command)}")
    success = run_command_direct_output(  # 여기를 수정
        full_bash_command,
        success_message=f"Bash 스크립트 '{script_path_relative_to_repo}' 실행 완료된 것 같습니다.",
        error_message=f"Bash 스크립트 '{script_path_relative_to_repo}' 실행 중 오류.",
    )
    return success


# --- Python 가상 환경 및 패키지 설치 ---
def setup_python_venv_and_packages(
    msys2_root, username, project_python_executable_path, requirements_list
):
    """지정된 파이썬으로 가상 환경을 만들고 패키지를 설치합니다."""
    # 가상 환경 경로 (파워셸 스크립트와 동일하게)
    venv_path = os.path.join(msys2_root, "home", username, "python", "msys2-venv")

    print(f"Python 가상 환경 설정 중: {venv_path}")
    if not os.path.exists(project_python_executable_path):
        print(
            f"오류: Python 실행 파일을 찾을 수 없습니다: {project_python_executable_path}"
        )
        return False

    # 1. 가상 환경 생성
    print(f"'{project_python_executable_path}'을(를) 사용하여 가상 환경 생성 중...")
    # python -m venv <venv_path>
    success, _ = run_command(
        [project_python_executable_path, "-m", "venv", venv_path],
        success_message=f"가상 환경 생성 성공: {venv_path}",
        error_message="가상 환경 생성 실패.",
    )
    if not success:
        return False

    # 가상 환경 내의 python.exe 및 pip.exe 경로
    venv_python_exe = os.path.join(venv_path, "Scripts", "python.exe")
    venv_pip_exe = os.path.join(venv_path, "Scripts", "pip.exe")

    if not os.path.exists(venv_python_exe):
        print(
            f"오류: 가상 환경 내 Python 실행 파일을 찾을 수 없습니다: {venv_python_exe}"
        )
        return False

    # 2. pip 업그레이드
    print("가상 환경 내 pip 업그레이드 중...")
    success, _ = run_command(
        [venv_python_exe, "-m", "pip", "install", "--upgrade", "pip"],
        success_message="pip 업그레이드 성공.",
        error_message="pip 업그레이드 실패.",
    )
    if not success:
        return False  # 또는 경고만 하고 계속 진행할 수도 있음

    # 3. 패키지 설치
    if requirements_list:
        print(f"가상 환경에 패키지 설치 중: {', '.join(requirements_list)}")
        # pip install <package1> <package2> ...
        success, _ = run_command(
            [venv_pip_exe, "install"] + requirements_list,
            success_message="패키지 설치 성공.",
            error_message="패키지 설치 실패.",
        )
        if not success:
            return False

    print("Python 가상 환경 및 패키지 설정 완료.")
    return True
