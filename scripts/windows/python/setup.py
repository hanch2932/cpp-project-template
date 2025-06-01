# main_setup.py (메인 실행 스크립트)

import os
import sys
import time
import getpass  # 사용자 이름 가져오기 (os.getlogin()은 특정 환경에서 문제 가능성)
import subprocess
import shutil

# 현재 스크립트의 디렉토리 (저장소 루트로 가정하거나, 상위로 설정 가능)
# 이 스크립트가 저장소 루트에 있다고 가정.
# 만약 특정 하위 폴더(예: 'scripts')에 있다면, REPO_ROOT_DIR을 적절히 수정.

current_script_path = os.path.abspath(__file__)
current_script_dir = os.path.dirname(current_script_path)
REPO_ROOT_DIR = os.path.dirname(current_script_dir)
POWERSHELL_SCRIPTS_DIR = os.path.join(
    REPO_ROOT_DIR, "powershell"
)  # Bash 스크립트 실행 시 CWD 기준
BASH_SCRIPTS_DIR = os.path.join(REPO_ROOT_DIR, "bash")  # 실제 .sh 파일들이 있는 곳

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

# setup_utils.py 에서 함수 임포트
# setup_utils.py가 같은 디렉토리에 있거나, sys.path에 추가되어야 함.
try:
    from setup_utils import (
        is_admin,
        run_as_admin_if_needed,
        run_command_direct_output,
        set_system_environment_variable,
        add_to_system_path,
        download_msys2_installer,
        install_msys2,
        remove_msys2_installer,
        configure_powershell_profile_utf8,
        run_msys2_bash_script,
        setup_python_venv_and_packages,
        update_current_session_path_from_registry,
    )
except ImportError as e:
    print(
        "오류: setup_utils.py를 찾을 수 없습니다. 스크립트와 같은 디렉토리에 있는지 확인하세요."
    )
    print(f"ImportError: {e}")
    print(f"sys.path: {sys.path}")  # 디버깅을 위해 sys.path 출력

    sys.exit(1)


# --- 설정 값 (파워셸 스크립트 참고) ---
MSYS2_INSTALLER_GIT_TAG = "2025-02-21"  # 버전 업데이트 시 직접 변경 필요
MSYS2_ROOT_DIR = r"C:\msys64"  # 기본 설치 경로
TEMP_DOWNLOAD_DIR = os.path.join(os.getenv("TEMP", "C:\\Temp"), "dev_setup_downloads")

# Python 3.13 winget ID (사용자 스크립트 기준)
PYTHON_WINGET_ID = "Python.Python.3.13"
# 설치된 Python 3.13의 예상 경로 (winget 기본 설치 경로 가정)
# 사용자마다 다를 수 있으므로, winget show Python.Python.3.13 등으로 확인하거나
# 설치 후 PATH에서 찾는 로직이 더 견고함.
# 여기서는 파워셸의 setup-python.ps1 경로를 단순화하여 사용.
PYTHON_EXECUTABLE_PATH = (
    rf"C:\Users\{getpass.getuser()}\AppData\Local\Programs\Python\Python313\python.exe"
)
# 또는 winget으로 설치 후 PATH에 잡히는 'python' 또는 'python3.13'을 사용
# PYTHON_EXECUTABLE_PATH = "python" # PATH에 의존

# Python 가상 환경에 설치할 패키지
PYTHON_VENV_PACKAGES = ["mkdocs", "mkdocs-material", "mkdoxy"]

# VSCode 확장
VSCODE_EXTENSIONS = [
    "ms-vscode.cpptools-extension-pack",
    "llvm-vs-code-extensions.vscode-clangd",
    "ms-python.python",
]


def main():
    # 0. 관리자 권한 확인 및 요청
    run_as_admin_if_needed()  # 실패 시 여기서 종료됨

    print("=" * 50)
    print("개발 환경 설정 스크립트 (Python 버전)")
    print("=" * 50)
    print("이 작업은 최초 실행 시 시간이 오래 걸릴 수 있습니다.")
    print("인터넷 상태 및 컴퓨터 환경에 따라 소요 시간이 달라질 수 있습니다.")
    print("작업이 완료될 때까지 기다려 주세요...")
    time.sleep(5)
    print("\n")

    # 1. winget을 사용한 기본 프로그램 설치
    print_section_header("기본 프로그램 설치 (winget)")
    winget_common_args = [
        "--accept-package-agreements",
        "--accept-source-agreements",
        "-e",
    ]

    programs_to_install = {
        "PowerShell (최신)": "Microsoft.PowerShell",
        "VSCode": "Microsoft.VisualStudioCode",
    }

    all_programs_installed_ok = True
    for name, prog_id in programs_to_install.items():
        print(f"--- {name} 설치 시도 ---")
        success = run_command_direct_output(
            ["winget", "install"] + winget_common_args + ["--id", prog_id],
            success_message=f"{name} 설치/업데이트 성공 또는 이미 최신.",
            error_message=f"{name} 설치/업데이트 실패.",
        )
        # if not success:
        #     all_programs_installed_ok = False
        #     if prog_id == PYTHON_WINGET_ID:  # Python 설치 실패는 중요
        #         print(f"경고: 필수 구성 요소인 {name} 설치에 실패했습니다.")
        print("-" * 20 + "\n")

    if not all_programs_installed_ok:
        print("경고: 일부 프로그램 설치에 실패했습니다. 로그를 확인하세요.")
    else:
        print("모든 기본 프로그램 설치 시도 완료.")
    print_section_footer()

    # (중요) 프로그램 설치 후 PATH 변경이 있을 수 있으므로, 현재 세션 PATH 갱신
    update_current_session_path_from_registry()

    # 2. PowerShell 프로필 UTF-8 설정 (setup.ps1의 기능)
    print_section_header("PowerShell 프로필 UTF-8 설정")
    configure_powershell_profile_utf8()
    print_section_footer()

    # 3. MSYS2 설치 (install-msys2.ps1의 기능)
    print_section_header("MSYS2 설치")
    msys2_installer_exe = None
    if (
        not os.path.isdir(MSYS2_ROOT_DIR)
        or input(
            f"'{MSYS2_ROOT_DIR}' 디렉터리가 이미 존재합니다. MSYS2를 다시 설치하시겠습니까? (y/n): "
        ).lower()
        == "y"
    ):

        if os.path.isdir(MSYS2_ROOT_DIR):
            print(
                f"경고: 기존 '{MSYS2_ROOT_DIR}' 디렉터리가 존재합니다. 덮어쓰거나 문제가 발생할 수 있습니다."
            )

        msys2_version_tag = MSYS2_INSTALLER_GIT_TAG
        msys2_clean_tag = msys2_version_tag.replace("-", "")
        msys2_url = f"https://github.com/msys2/msys2-installer/releases/download/{msys2_version_tag}/msys2-x86_64-{msys2_clean_tag}.exe"

        msys2_installer_exe = download_msys2_installer(msys2_url, TEMP_DOWNLOAD_DIR)
        if msys2_installer_exe:
            if not install_msys2(msys2_installer_exe, MSYS2_ROOT_DIR):
                print("MSYS2 설치 실패. 관련된 다음 단계를 건너뛸 수 있습니다.")
            else:
                print("MSYS2 설치 성공.")
        else:
            print("MSYS2 설치 프로그램 다운로드 실패. MSYS2 설치를 건너뜁니다.")
    else:
        print(f"MSYS2가 이미 '{MSYS2_ROOT_DIR}'에 설치된 것으로 간주합니다.")

    if msys2_installer_exe:  # 다운로드 했다면 삭제
        remove_msys2_installer(msys2_installer_exe)
    print_section_footer()

    # 4. MSYS2 관련 환경 변수 설정 (setup.ps1의 기능)
    print_section_header("MSYS2 환경 변수 설정")
    # 파워셸 스크립트에서 $MSYS2_PATH는 가상환경 경로를 포함했음.
    # 가상환경은 Python 설정 단계에서 만들어지므로, 여기서는 기본 경로만 설정하거나,
    # 또는 Python 설정 후 이 부분을 다시 실행하거나, 순서를 조정해야 함.
    # 파워셸 스크립트는 MSYS2_PATH를 String으로 설정하고, Path에 %MSYS2_PATH%를 추가함.
    # 우선 MSYS2_ROOT만 설정. MSYS2_PATH는 Python venv 생성 후 설정.

    set_system_environment_variable(
        "MSYS2_ROOT", MSYS2_ROOT_DIR, "REG_SZ"
    )  # String 타입

    # MSYS2의 기본 bin 경로들을 시스템 Path에 추가 (필요시)
    # 예: add_to_system_path(os.path.join(MSYS2_ROOT_DIR, "usr", "bin"))
    #      add_to_system_path(os.path.join(MSYS2_ROOT_DIR, "ucrt64", "bin"))
    # 파워셸 스크립트는 %MSYS2_PATH%를 사용하므로, 여기서는 MSYS2_PATH 변수만 정의하고
    # Path에 %MSYS2_PATH%를 추가하는 것은 나중에.

    # 파워셸 스크립트의 MSYS2_PATH 정의 (가상환경 경로 포함)
    # $MSYS2_PATH = "$MSYS2_ROOT\home\%USERNAME%\python\msys2-venv\Scripts;$MSYS2_ROOT\ucrt64\bin;$MSYS2_ROOT\usr\bin"
    # 이 MSYS2_PATH는 Python 가상환경 생성 후에 완전해짐.
    # 따라서 여기서는 %MSYS2_PATH%를 Path에 추가하는 것만 수행하고,
    # MSYS2_PATH 자체의 정의는 Python venv 설정 후로 미루거나,
    # 또는 기본 경로들만 포함된 MSYS2_BASE_PATHS 같은 변수를 만들고 그걸 Path에 추가.
    #
    # 파워셸의 흐름:
    # 1. MSYS2_ROOT, MSYS2_PATH (String) 시스템 변수 설정
    # 2. 시스템 Path에 "%MSYS2_PATH%" (문자열) 추가
    # 3. bash 스크립트 실행 (pacman 등)
    # 4. Python venv 설정 (setup-python.ps1 -> MSYS2_ROOT/home/.../msys2-venv 생성)
    #
    # 즉, MSYS2_PATH 시스템 변수는 초기에 설정되지만, 그 값에 포함된 venv 경로는
    # Python 설정 단계 전까지는 실제로 존재하지 않을 수 있음.
    # 그럼에도 불구하고 %MSYS2_PATH%를 시스템 Path에 추가하는 것은 유효함 (나중에 확장되므로).

    # 파워셸처럼 MSYS2_PATH를 String으로 정의하고 시스템 Path에 %MSYS2_PATH% 추가
    # 이 MSYS2_PATH는 Python venv 생성 후 완전한 의미를 가짐.
    # 사용자 이름 가져오기
    # current_username = getpass.getuser()
    msys2_venv_scripts_path = os.path.join("C:\\", "python", "msys2-venv", "Scripts")

    # MSYS2_PATH 정의 (String 타입으로 설정할 것이므로, %VAR% 형태는 없음)
    msys2_path_value = f"{msys2_venv_scripts_path};{os.path.join(MSYS2_ROOT_DIR, 'ucrt64', 'bin')};{os.path.join(MSYS2_ROOT_DIR, 'usr', 'bin')}"

    set_system_environment_variable(
        "MSYS2_PATH", msys2_path_value, "REG_SZ"
    )  # String 타입

    # 시스템 Path에 "%MSYS2_PATH%" 문자열 추가
    # add_to_system_path는 내부적으로 REG_EXPAND_SZ로 Path를 설정하므로, "%MSYS2_PATH%"가 올바르게 확장됨.
    add_to_system_path("%MSYS2_PATH%", add_front=True)
    print_section_footer()

    # (중요) 환경 변수 변경 후 PATH 갱신
    update_current_session_path_from_registry()

    # 5. MSYS2 초기 설정 (Bash 스크립트 실행)
    print_section_header("MSYS2 초기 설정 (Bash 스크립트)")
    if os.path.isdir(MSYS2_ROOT_DIR):  # MSYS2가 설치되었거나 이미 존재한다고 가정
        bash_scripts_to_run = [
            "setup-pacman.sh",
            "update-packages.sh",  # 1차 업데이트
            "update-packages.sh",  # 2차 업데이트 (MSYS2 권장)
            "install-deps.sh",
        ]
        for script_rel_path in bash_scripts_to_run:
            # run_msys2_bash_script의 두 번째 인자는 repo 루트 기준 .sh 파일 경로
            # powershell 디렉토리를 기준으로 bash 스크립트를 호출하던 파워셸과는 다름.
            # 여기서는 repo_root_dir를 기준으로 bash 스크립트의 상대경로를 전달.
            # setup_utils.run_msys2_bash_script 내부에서 이 경로를 처리함.
            # setup_utils의 run_msys2_bash_script는 파워셸의 $PSScriptRoot 동작을 모방.
            # 즉, script_path_relative_to_repo는 '../bash/script.sh' 같은 형태여야 함.
            # 이를 위해, bash 스크립트 이름만 전달하고, 내부에서 '../bash/'를 붙이도록 수정하거나,
            # 여기서 정확한 상대 경로를 구성.
            #
            # 파워셸 스크립트의 호출: & $bashPath -lc "cd '$PSScriptRoot'; ../bash/setup-pacman.sh"
            # 여기서 '$PSScriptRoot'는 REPO_ROOT_DIR/powershell 이었음.
            # run_msys2_bash_script 의 두번째 인자는 이 'cd' 이후의 상대 경로.
            # 예: "../bash/setup-pacman.sh"

            # script_rel_path가 "bash/setup-pacman.sh" 이므로,
            # 이를 "../bash/setup-pacman.sh" 형태로 변환.
            # 또는 run_msys2_bash_script가 이 변환을 하도록. (현재는 후자)
            # setup_utils.py의 run_msys2_bash_script는
            # script_path_relative_to_repo 를 'bash/script.sh' 형태로 받고,
            # 내부에서 bash_command_string = f"cd '{msys_style_powershell_dir}'; {script_path_relative_to_repo.replace('bash/', '../bash/')}"
            # 로 변환하므로, 여기서는 "bash/script.sh" 형태로 전달.

            full_script_path_in_bash_dir = os.path.join(
                BASH_SCRIPTS_DIR, os.path.basename(script_rel_path)
            )
            if not os.path.exists(full_script_path_in_bash_dir):
                print(
                    f"경고: Bash 스크립트 '{full_script_path_in_bash_dir}'를 찾을 수 없습니다. 건너뜁니다."
                )
                continue

            print(f"--- {os.path.basename(full_script_path_in_bash_dir)} 실행 ---")
            run_msys2_bash_script(
                MSYS2_ROOT_DIR, "bash/" + script_rel_path, REPO_ROOT_DIR
            )  # REPO_ROOT_DIR 전달
            print("-" * 20 + "\n")
    else:
        print("MSYS2가 설치되지 않아 Bash 스크립트 실행을 건너뜁니다.")
    print_section_footer()

    # 6. Python 가상 환경 설정 및 패키지 설치 (setup-python.ps1의 기능)
    # print_section_header("Python 가상 환경 및 패키지 설치")
    # if os.path.isdir(MSYS2_ROOT_DIR):  # MSYS2 설치 확인
    #     # winget으로 설치한 Python 경로 사용
    #     # PYTHON_EXECUTABLE_PATH가 실제 설치된 경로를 가리키는지 확인 필요.
    #     # 또는 PATH에서 'python' 또는 'python3.13'을 사용.
    #     # 여기서는 PYTHON_EXECUTABLE_PATH 변수를 그대로 사용.
    #     if not os.path.exists(PYTHON_EXECUTABLE_PATH):
    #         print(
    #             f"경고: Python 실행 파일 '{PYTHON_EXECUTABLE_PATH}'를 찾을 수 없습니다."
    #         )
    #         print(
    #             "winget으로 Python 설치가 올바르게 되었는지, 또는 경로가 정확한지 확인하세요."
    #         )
    #         print("Python 가상 환경 설정을 건너뜁니다.")
    #     else:
    #         setup_python_venv_and_packages(
    #             MSYS2_ROOT_DIR,
    #             current_username,  # 사용자 이름
    #             PYTHON_EXECUTABLE_PATH,
    #             PYTHON_VENV_PACKAGES,
    #         )
    # else:
    #     print("MSYS2가 설치되지 않아 Python 가상 환경 설정을 건너뜁니다.")
    # print_section_footer()

    if os.path.isdir(r"C:\python\msys2-venv\Scripts"):
        run_command_direct_output(  # 여기를 수정
            [r"C:\python\msys2-venv\Scripts\pip", "install"] + PYTHON_VENV_PACKAGES,
            success_message="패키지 설치 성공.",
            error_message="패키지 설치 실패.",
        )

    # 7. VSCode 확장 설치 (setup.ps1의 기능)
    print_section_header("VSCode 확장 설치")
    # 'code' 명령어가 PATH에 있어야 함 (VSCode 설치 시 보통 추가됨)
    # PATH 갱신이 필요할 수 있음. update_current_session_path_from_registry() 호출됨.

    # code 명령어 존재 확인
    # code_exe_path = None
    # try:
    #     result = subprocess.run(
    #         ["where", "code"],
    #         capture_output=True,
    #         text=True,
    #         check=False,
    #         encoding="utf-8",
    #     )
    #     if result.returncode == 0 and result.stdout.strip():
    #         code_exe_path = result.stdout.strip().splitlines()[0]
    # except Exception:
    #     pass

    code_exe_path = shutil.which("code")

    if code_exe_path:
        print(f"VSCode 실행 파일 확인: {code_exe_path}")
        for extension_id in VSCODE_EXTENSIONS:
            print(f"--- {extension_id} 설치 시도 ---")
            run_command_direct_output(
                [
                    code_exe_path,
                    "--install-extension",
                    extension_id,
                    "--force",
                ],  # --force는 이미 있어도 재설치/업데이트 시도
                success_message=f"VSCode 확장 '{extension_id}' 설치/업데이트 성공.",
                error_message=f"VSCode 확장 '{extension_id}' 설치/업데이트 실패.",
            )
            print("-" * 20 + "\n")
    else:
        print(
            "VSCode 'code' 명령어를 찾을 수 없습니다. VSCode가 PATH에 설치되었는지 확인하세요."
        )
        print("VSCode 확장 설치를 건너뜁니다.")
    print_section_footer()

    print("=" * 50)
    print("모든 개발 환경 설정 스크립트(Python)가 완료되었습니다.")
    print("시스템 전체에 변경 사항을 적용하려면 컴퓨터를 재시작하는 것이 좋습니다.")
    print("=" * 50)
    # input("Enter 키를 눌러 종료합니다...")


def print_section_header(title):
    print(f"\n{'=' * 10} {title} {'=' * 10}")


def print_section_footer():
    print(f"{'=' * (30 + len(' 섹션 완료 '))}\n")


if __name__ == "__main__":
    # 스크립트 파일 구조 가정:
    # REPO_ROOT/
    #   main_setup.py
    #   setup_utils.py
    #   powershell/  (Bash 스크립트 실행 시 CWD 설정에 사용될 수 있음, 또는 불필요)
    #   bash/
    #     setup-pacman.sh
    #     ...

    # REPO_ROOT_DIR 과 POWERSHELL_SCRIPTS_DIR, BASH_SCRIPTS_DIR 경로 확인
    # setup_utils.run_msys2_bash_script 함수에서 REPO_ROOT_DIR을 사용하여
    # bash 스크립트의 정확한 경로를 찾고, 파워셸 스크립트 실행 시의 CWD를 모방합니다.

    main()
