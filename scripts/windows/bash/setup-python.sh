#!/bin/bash

echo "Python 초기 설정 중..."
/ucrt64/bin/python -m venv --system-site-packages ~/python-venv
grep -qxF "export PATH=\"\$HOME/python-venv/bin:\$PATH\"" /etc/profile || echo "export PATH=\"\$HOME/python-venv/bin:\$PATH\"" >> /etc/profile
echo "완료"
echo ""
