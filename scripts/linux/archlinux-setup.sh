echo "개발 관련 패키지를 설치하는 중..."
sudo pacman -S --needed \
               base-devel \
               cmake \
               ninja \
               gcc \
               gdb \
               clang \
               sdl3 \
               vulkan-headers \
               vulkan-validation-layers \
               vulkan-tools
echo "설치 완료"
echo ""

if command -v "code" > /dev/null 2>&1; then
  echo "VSCode 확장을 설치합니다."
  
  code --install-extension ms-vscode.cpptools-extension-pack
  code --install-extension llvm-vs-code-extensions.vscode-clangd
  code --install-extension ms-python.python
else
  echo "VSCode가 설치되어 있지 않습니다. 확장 설치를 건너뜁니다."
fi
echo ""

echo "개발환경 설정이 완료되었습니다."
