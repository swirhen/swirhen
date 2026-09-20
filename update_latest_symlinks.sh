#!/bin/bash
set -euo pipefail

# ==============================================================================
# 設定項目 (後からプレフィックスやリンク名を簡単に追加・整備できます)
# ==============================================================================
# デフォルトの対象ディレクトリ (引数で指定された場合はそちらを優先)
DEFAULT_TARGET_DIR="/data/share/temp"

# 書式: "プレフィックス:リンク名"
#   - プレフィックス + 数字2桁で始まるディレクトリ (例: d2607-09, c2607-12, v2026) を検索します
#   - リンク名に "{Same}" または空文字を指定した場合は、リモートディレクトリと同名で作成します
#   - "プレフィックス:パターン:リンク名" の3要素で詳細なパターンを指定することも可能です
TARGET_MAPPINGS=(
  "d:_dojin"
  "c:_manga"
  "v:_av"
  "cos:_cos"
)

# スクリプトの配置ディレクトリを特定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERBOSE=0
DRY_RUN=0
TARGET_DIR=""

show_usage() {
  cat << EOF
Usage: $0 [options] [target_dir]

プレフィックス+数字2桁 (例: d2607-09, c2607-12, v2026) のディレクトリの中で
最新のものを検出し、設定されたリンク名へのシンボリックリンクを張り直します。

Options:
  -d, --dry-run   リンクの作成・更新を行わず、シミュレーション結果のみを表示します
  -v, --verbose   詳細なログを表示します
  -h, --help      このヘルプメッセージを表示して終了します

Arguments:
  target_dir      対象ディレクトリ（省略時はデフォルト: $DEFAULT_TARGET_DIR）
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

TARGET_DIR="${1:-$DEFAULT_TARGET_DIR}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "エラー: 対象ディレクトリが存在しません: $TARGET_DIR" >&2
  exit 1
fi

[ $VERBOSE -eq 1 ] && echo "=== [DEBUG] 対象ディレクトリ: $TARGET_DIR ==="

# 相対パスでのシンボリックリンク作成のため対象ディレクトリに移動
cd "$TARGET_DIR"

for spec in "${TARGET_MAPPINGS[@]}"; do
  # コロン区切りでパース (2要素: prefix:link_name / 3要素: prefix:pattern:link_name)
  IFS=':' read -r field1 field2 field3 <<< "$spec"
  if [ -n "$field3" ]; then
    prefix="$field1"
    pattern="$field2"
    link_name="$field3"
  else
    prefix="$field1"
    pattern="${prefix}[0-9][0-9]*"
    link_name="$field2"
  fi

  [ $VERBOSE -eq 1 ] && echo "--- 検査中: Prefix='$prefix' / 設定='$link_name' (パターン: $pattern) ---"

  # パターンに一致するディレクトリ一覧を取得し、自然順ソートで最新を取得
  LATEST_DIR=$(find . -maxdepth 1 -mindepth 1 -type d -name "$pattern" -printf "%f\n" 2>/dev/null | sort -V | tail -n 1 || true)

  if [ -z "$LATEST_DIR" ]; then
    echo "警告: プレフィックス '$prefix' (パターン: $pattern) に一致するディレクトリが見つかりませんでした。スキップします。"
    continue
  fi

  # リンク名の決定 (同名指定 "{Same}" または空の場合はディレクトリと同名)
  if [ "$link_name" = "{Same}" ] || [ -z "$link_name" ]; then
    actual_link_name="$LATEST_DIR"

    # 同名リンク運用の場合、もし過去バージョンのシンボリックリンクが残っていれば削除
    while IFS= read -r old_link; do
      [ -z "$old_link" ] && continue
      if [ "$old_link" != "$actual_link_name" ]; then
        if [ $DRY_RUN -eq 1 ]; then
          echo "[DRY-RUN] [CLEANUP] 旧バージョンのリンク '$old_link' を削除予定"
        else
          rm -f "$old_link"
          echo "[CLEANUP] 旧バージョンのリンク '$old_link' を削除しました"
        fi
      fi
    done < <(find . -maxdepth 1 -mindepth 1 -type l -name "$pattern" -printf "%f\n" 2>/dev/null || true)
  else
    actual_link_name="$link_name"
  fi

  # リンク先と同名の通常ファイル/ディレクトリが存在する場合は事故防止のためスキップ
  if [ -e "$actual_link_name" ] && [ ! -L "$actual_link_name" ]; then
    echo "エラー: '$actual_link_name' はシンボリックリンクではなく実ファイルまたはディレクトリです。スキップします。" >&2
    continue
  fi

  # 現在のリンク先を取得（存在しない場合は空文字）
  CURRENT_TARGET=""
  if [ -L "$actual_link_name" ]; then
    CURRENT_TARGET=$(readlink "$actual_link_name" || true)
  fi

  [ $VERBOSE -eq 1 ] && echo "[DEBUG] 最新ディレクトリ: $LATEST_DIR, 現在のリンク先: ${CURRENT_TARGET:-<なし>}"

  # すでに最新を指している場合
  if [ "$CURRENT_TARGET" = "$LATEST_DIR" ]; then
    echo "[$actual_link_name] 変更なし (既に最新 '$LATEST_DIR' を指しています)"
    continue
  fi

  # リンク更新
  if [ $DRY_RUN -eq 1 ]; then
    if [ -n "$CURRENT_TARGET" ]; then
      echo "[DRY-RUN] [$actual_link_name] 更新予定: $CURRENT_TARGET -> $LATEST_DIR"
    else
      echo "[DRY-RUN] [$actual_link_name] 新規作成予定: -> $LATEST_DIR"
    fi
  else
    ln -sfn "$LATEST_DIR" "$actual_link_name"
    if [ -n "$CURRENT_TARGET" ]; then
      echo "[$actual_link_name] リンクを更新しました: $CURRENT_TARGET -> $LATEST_DIR"
    else
      echo "[$actual_link_name] リンクを新規作成しました: -> $LATEST_DIR"
    fi
  fi
done
