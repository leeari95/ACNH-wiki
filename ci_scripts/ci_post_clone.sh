#!/bin/sh
set -e

# ✅ 프로젝트 최상단 폴더로 이동
cd ..

# ✅ mise 설치
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# Output the current PATH for debugging
echo "❗️Current PATH: $PATH"

echo "❗️mise version"
mise --version
echo "❗️mise install"
mise install # Installs the version from .mise.toml
eval "$(mise activate bash --shims)"

echo "❗️mise doctor"
mise doctor # verify the output of mise is correct on CI

# ✅ Tuist 설치 및 프로젝트 생성
echo "❗️tuist install"
tuist install
echo "❗️tuist generate"
tuist generate # Generate the Xcode Project using Tuist