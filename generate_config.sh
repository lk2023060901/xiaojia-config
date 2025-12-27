#!/bin/bash
set -e

# 示例工程：使用本目录下的 Excel 和 schema，
# 通过 Luban 生成 JSON 配置到 output 目录

# 脚本所在目录（支持从任意工作目录调用）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# 允许在更高版本 .NET 运行时（如仅安装 .NET 10）上运行针对 net8.0 的 Luban
export DOTNET_ROLL_FORWARD=Major

DOTNET_MIN_MAJOR=8
DOTNET_INSTALL_DIR="${DOTNET_INSTALL_DIR:-$HOME/.dotnet}"

install_dotnet() {
  echo "正在尝试自动安装 .NET SDK ($DOTNET_MIN_MAJOR.x)…"

  mkdir -p "$DOTNET_INSTALL_DIR"
  local install_script="$DOTNET_INSTALL_DIR/dotnet-install.sh"

  if ! command -v curl >/dev/null 2>&1; then
    echo "错误：未找到 curl，无法自动下载 dotnet 安装脚本。"
    echo "请手动安装 .NET SDK： https://dotnet.microsoft.com/download"
    exit 1
  fi

  echo "下载 dotnet 安装脚本到: $install_script"
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$install_script"
  chmod +x "$install_script"

  # 安装指定通道（8.0），仅影响当前用户目录。
  "$install_script" --channel "$DOTNET_MIN_MAJOR.0" --install-dir "$DOTNET_INSTALL_DIR" --no-path

  # 将新安装的 dotnet 放到当前脚本 PATH 最前面。
  export DOTNET_ROOT="$DOTNET_INSTALL_DIR"
  export PATH="$DOTNET_ROOT:$PATH"

  local ver
  ver="$(dotnet --version 2>/dev/null || true)"
  if [ -z "$ver" ]; then
    echo "自动安装 .NET 后仍未检测到 dotnet 命令，请检查网络或手动安装。"
    exit 1
  fi

  echo "dotnet 安装完成，当前版本: $ver"
}

ensure_dotnet() {
  local has_dotnet=0
  if command -v dotnet >/dev/null 2>&1; then
    has_dotnet=1
  fi

  if [ "$has_dotnet" -eq 0 ]; then
    # 如果 PATH 里没有，但此前已经通过本脚本安装在 DOTNET_INSTALL_DIR 下，
    # 直接把该目录加入 PATH，避免每次都重新执行安装脚本。
    local candidate="$DOTNET_INSTALL_DIR/dotnet"
    if [ -x "$candidate" ]; then
      export DOTNET_ROOT="$DOTNET_INSTALL_DIR"
      export PATH="$DOTNET_ROOT:$PATH"
      has_dotnet=1
      echo "检测到本地 .NET 安装在: $candidate，已加入 PATH"
    else
      echo "未检测到 dotnet 命令，准备自动安装 .NET $DOTNET_MIN_MAJOR.x…"
      install_dotnet
    fi
  fi

  # 再次获取版本信息（可能刚安装完）
  local ver
  ver="$(dotnet --version 2>/dev/null || true)"
  if [ -z "$ver" ]; then
    echo "dotnet 安装或检测失败，请手动安装 .NET SDK（$DOTNET_MIN_MAJOR 及以上）后重试。"
    exit 1
  fi

  local major="${ver%%.*}"
  if [[ "$major" =~ ^[0-9]+$ ]] && [ "$major" -lt "$DOTNET_MIN_MAJOR" ]; then
    echo "检测到 dotnet 版本为: $ver，小于要求的 $DOTNET_MIN_MAJOR.x，准备为当前用户安装更新版本…"
    install_dotnet
  fi
}

find_luban_exe() {
  # 优先使用项目 bin 目录下的可执行文件
  local platform="$(uname -s)"
  case "$platform" in
    Linux*)     LUBAN_EXE="$PROJECT_ROOT/bin/linux/Luban" ;;
    Darwin*)    LUBAN_EXE="$PROJECT_ROOT/bin/macos/Luban" ;;
    *)          LUBAN_EXE="" ;;
  esac

  if [ -n "$LUBAN_EXE" ] && [ -f "$LUBAN_EXE" ]; then
    echo "$LUBAN_EXE"
    return 0
  fi

  # 备选：查找 Luban.dll
  local candidates=(
    "$WORKSPACE/Tools/Luban/Luban.dll"
    "$WORKSPACE/Tools/luban/Tools/Luban/Luban.dll"
  )
  local dll=""
  for dll in "${candidates[@]}"; do
    if [ -f "$dll" ]; then
      echo "$dll"
      return 0
    fi
  done
  return 0
}

prepare_luban() {
  LUBAN_EXE="$(find_luban_exe)"
  if [ -z "$LUBAN_EXE" ]; then
    echo "错误：未找到 Luban 可执行文件"
    echo "请确保以下路径之一存在："
    echo "  - $PROJECT_ROOT/bin/macos/Luban (macOS)"
    echo "  - $PROJECT_ROOT/bin/linux/Luban (Linux)"
    echo "  - $WORKSPACE/Tools/Luban/Luban.dll (备选)"
    exit 1
  fi

  # 判断是可执行文件还是 DLL
  if [[ "$LUBAN_EXE" == *.dll ]]; then
    IS_DLL=1
    echo "使用 Luban DLL: $LUBAN_EXE"
    ensure_dotnet
  else
    IS_DLL=0
    echo "使用 Luban 可执行文件: $LUBAN_EXE"
  fi
}

prepare_luban

# 输出目录
BIN_CLIENT_DIR="$PROJECT_ROOT/output/bin/client"
JSON_SERVER_DIR="$PROJECT_ROOT/output/json/server"
CODE_CPP_DIR="$PROJECT_ROOT/output/code/cpp"
CODE_GO_DIR="$PROJECT_ROOT/output/code/go"

mkdir -p "$BIN_CLIENT_DIR" "$JSON_SERVER_DIR" "$CODE_CPP_DIR" "$CODE_GO_DIR"

run_luban() {
  if [ "$IS_DLL" -eq 1 ]; then
    dotnet "$LUBAN_EXE" "$@"
  else
    "$LUBAN_EXE" "$@"
  fi
}

(
  cd "$PROJECT_ROOT"

  echo "生成客户端 bin 配置到: $BIN_CLIENT_DIR"
  run_luban \
    -t client \
    -d bin \
    --conf "$SCRIPT_DIR/luban.conf" \
    -x outputDataDir="$BIN_CLIENT_DIR"

  echo "生成服务端 JSON 配置到: $JSON_SERVER_DIR"
  run_luban \
    -t server \
    -d json \
    --conf "$SCRIPT_DIR/luban.conf" \
    -x outputDataDir="$JSON_SERVER_DIR"

  echo "生成 C++ 解析代码到: $CODE_CPP_DIR"
  run_luban \
    -t all \
    -c cpp-sharedptr-bin \
    --conf "$SCRIPT_DIR/luban.conf" \
    -x outputCodeDir="$CODE_CPP_DIR"

  echo "生成 Go 解析代码到: $CODE_GO_DIR"
  run_luban \
    -t all \
    -c go-json \
    --conf "$SCRIPT_DIR/luban.conf" \
    -x outputCodeDir="$CODE_GO_DIR" \
    -x lubanGoModule=xdooria/cfg
)

echo "生成完成，数据输出目录："
echo "  client (bin):  $BIN_CLIENT_DIR"
echo "  server (json): $JSON_SERVER_DIR"
echo "代码输出目录："
echo "  C++: $CODE_CPP_DIR"
echo "  Go:  $CODE_GO_DIR"
