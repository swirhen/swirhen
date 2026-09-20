#!/bin/bash
set -euo pipefail

# スクリプトの配置ディレクトリを特定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERBOSE=0
DRY_RUN=0
TARGET_DIR=""

show_usage() {
  cat << EOF
Usage: $0 [options] [target_dir]

dYYMM-MM および cYYMM-MM 形式のディレクトリの中で最新のものを検出し、
それぞれ _dojin, _manga へのシンボリックリンクを張り直します。

Options:
  -d, --dry-run   リンクの作成・更新を行わず、シミュレーション結果のみを表示します
  -v, --verbose   詳細なログを表示します
  -h, --help      このヘルプメッセージを表示して終了します

Arguments:
  target_dir      対象ディレクトリ（省略時はスクリプトが置かれているディレクトリ: $SCRIPT_DIR）
EOF
}

# オプション解析
while [[ $# -gt 0 && "$1" =~ ^- ]]; do
  case "$1" in
    -d|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "エラー: 不明なオプションです: $1" >&2
      show_usage >&2
      exit 1
      ;;
  esac
done

TARGET_DIR="${1:-$SCRIPT_DIR}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "エラー: 対象ディレクトリが存在しません: $TARGET_DIR" >&2
  exit 1
fi

[ $VERBOSE -eq 1 ] && echo "=== [DEBUG] 対象ディレクトリ: $TARGET_DIR ==="

# 更新対象の定義: "プレフィックス:パターン:リンク名"
TARGET_SPECS=(
  "d:d[0-9][0-9][0-9][0-9]-[0-9][0-9]:_dojin"
  "c:c[0-9][0-9][0-9][0-9]-[0-9][0-9]:_manga"
)

# 相対パスでのシンボリックリンク作成のため対象ディレクトリに移動
cd "$TARGET_DIR"

for spec in "${TARGET_SPECS[@]}"; do
  IFS=':' read -r prefix pattern link_name <<< "$spec"

  [ $VERBOSE -eq 1 ] && echo "--- 検査中: $link_name (パターン: $pattern) ---"

  # パターンに一致するディレクトリ一覧を取得し、自然順ソートで最新を取得
  LATEST_DIR=$(find . -maxdepth 1 -mindepth 1 -type d -name "$pattern" -printf "%f\n" 2>/dev/null | sort -V | tail -n 1 || true)

  if [ -z "$LATEST_DIR" ]; then
    echo "警告: '$pattern' に一致するディレクトリが見つかりませんでした。($link_name の更新をスキップします)"
    continue
  fi

  # リンク先と同名の通常ファイル/ディレクトリが存在する場合は事故防止のためスキップ
  if [ -e "$link_name" ] && [ ! -L "$link_name" ]; then
    echo "エラー: '$link_name' はシンボリックリンクではなく実ファイルまたはディレクトリです。スキップします。" >&2
    continue
  fi

  # 現在のリンク先を取得（存在しない場合は空文字）
  CURRENT_TARGET=""
  if [ -L "$link_name" ]; then
    CURRENT_TARGET=$(readlink "$link_name" || true)
  fi

  [ $VERBOSE -eq 1 ] && echo "[DEBUG] 最新ディレクトリ: $LATEST_DIR, 現在のリンク先: ${CURRENT_TARGET:-<なし>}"

  # すでに最新を指している場合
  if [ "$CURRENT_TARGET" = "$LATEST_DIR" ]; then
    echo "[$link_name] 変更なし (既に最新 '$LATEST_DIR' を指しています)"
    continue
  fi

  # リンク更新
  if [ $DRY_RUN -eq 1 ]; then
    if [ -n "$CURRENT_TARGET" ]; then
      echo "[DRY-RUN] [$link_name] 更新予定: $CURRENT_TARGET -> $LATEST_DIR"
    else
      echo "[DRY-RUN] [$link_name] 新規作成予定: -> $LATEST_DIR"
    fi
  else
    ln -sfn "$LATEST_DIR" "$link_name"
    if [ -n "$CURRENT_TARGET" ]; then
      echo "[$link_name] リンクを更新しました: $CURRENT_TARGET -> $LATEST_DIR"
    else
      echo "[$link_name] リンクを新規作成しました: -> $LATEST_DIR"
    fi
  fi
done
