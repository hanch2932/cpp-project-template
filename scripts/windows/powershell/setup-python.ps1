[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$MSYS2_ROOT = "C:\msys64"

Write-Host "Python 설정 중..."
& "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python313\python" -m venv "$MSYS2_ROOT\home\$env:USERNAME\python\msys2-venv"
& "$MSYS2_ROOT\home\$env:USERNAME\python\msys2-venv\Scripts\python" -m pip install --upgrade pip
& "$MSYS2_ROOT\home\$env:USERNAME\python\msys2-venv\Scripts\pip" install mkdocs mkdocs-material mkdoxy
Write-Host "완료"
Write-Host ""
