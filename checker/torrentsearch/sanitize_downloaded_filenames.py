#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# torrentsearch配下のダウンロード済みファイル名をWindows互換へ正規化
import argparse
import pathlib

import torrent_search_common as tsc

DOWNLOAD_DIR_ROOT = pathlib.Path('/data/share/temp/torrentsearch')
MAX_FILENAME_BYTES = 255


def sanitize_file_name(filename):
    path = pathlib.Path(filename)
    suffix = path.suffix
    stem = filename[:-len(suffix)] if suffix else filename
    safe_suffix = tsc.sanitize_filename(suffix, MAX_FILENAME_BYTES) if suffix else ''
    max_stem_bytes = MAX_FILENAME_BYTES - len(safe_suffix.encode('utf-8'))
    if max_stem_bytes < 1:
        safe_suffix = ''
        max_stem_bytes = MAX_FILENAME_BYTES
    safe_stem = tsc.sanitize_filename(stem, max_stem_bytes)
    return f'{safe_stem}{safe_suffix}'


def find_rename_candidates(download_dir_root):
    candidates = []
    for download_dir in download_dir_root.glob('*'):
        if not download_dir.is_dir():
            continue
        for source in download_dir.iterdir():
            if not source.is_file():
                continue
            target = source.with_name(sanitize_file_name(source.name))
            if source != target:
                candidates.append((source, target))
    return candidates


def rename_files(candidates, execute):
    target_sources = {}
    for source, target in candidates:
        target_sources.setdefault(target, []).append(source)

    renamed_count = 0
    skipped_count = 0
    for source, target in candidates:
        has_collision = target.exists() or len(target_sources[target]) > 1
        if has_collision:
            print(f'SKIP collision: {source} -> {target}')
            skipped_count += 1
            continue
        if execute:
            source.rename(target)
            print(f'RENAMED: {source} -> {target}')
            renamed_count += 1
        else:
            print(f'WOULD RENAME: {source} -> {target}')

    return renamed_count, skipped_count


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='ダウンロード済みファイル名をWindows互換へ正規化します。')
    parser.add_argument('--execute', action='store_true', help='実際にリネームします。指定しない場合は表示のみです。')
    parser.add_argument('--root', type=pathlib.Path, default=DOWNLOAD_DIR_ROOT, help='ダウンロードルートディレクトリです。')
    args = parser.parse_args()

    candidates = find_rename_candidates(args.root)
    renamed_count, skipped_count = rename_files(candidates, args.execute)
    mode = 'execute' if args.execute else 'dry-run'
    print(f'mode: {mode}')
    print(f'candidates: {len(candidates)}')
    print(f'renamed: {renamed_count}')
    print(f'skipped: {skipped_count}')
