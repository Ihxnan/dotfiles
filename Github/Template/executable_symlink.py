#!/usr/bin/env python3

import argparse
import os
import sys
from collections import Counter
from pathlib import Path

script_path = Path(__file__).resolve()
src_dir = script_path.parent
default_target = Path("/usr/local/include/")

parser = argparse.ArgumentParser(
    description="将模板库 .hpp 扁平链接到 /usr/local/include/",
    epilog="""用例:
  sudo ./symlink.py                     # 建立所有 .hpp 的符号链接
  sudo ./symlink.py -c                  # 清空所有符号链接后重新建立
  sudo ./symlink.py -c -v               # 清理并链接，显示详细信息
  ./symlink.py -c -d                    # 预览清理与链接操作，不实际执行
  ./symlink.py -d                       # 预览链接操作，不实际执行""",
    formatter_class=argparse.RawDescriptionHelpFormatter,
)
parser.add_argument("-d", "--dry-run", action="store_true", help="仅预览，不执行实际操作")
parser.add_argument("-v", "--verbose", action="store_true", help="显示详细信息")
parser.add_argument("-c", "--clean", action="store_true", help="清空目标目录中所有符号链接")
args = parser.parse_args()

if os.geteuid() != 0 and not args.dry_run:
    print("错误: 此脚本需要管理员 (root) 权限才能写入到 /usr/local/include。")
    print(f"请使用 sudo 运行，例如: sudo {sys.argv[0]}")
    sys.exit(1)

# ── 清空所有符号链接 ────────────────────────────────────────────────
if args.clean and default_target.exists():
    cleaned = 0
    for item in sorted(default_target.iterdir()):
        if item.is_symlink():
            if args.dry_run:
                print(f"[dry-run] 将删除: {item} -> {os.readlink(item)}")
                cleaned += 1
            else:
                target = os.readlink(item)
                try:
                    item.unlink()
                    if args.verbose:
                        print(f"[清理] {item} -> {target}")
                    cleaned += 1
                except OSError as e:
                    print(f"[失败] 无法删除 {item}: {e}")
    if cleaned > 0:
        print(f"已清理 {cleaned} 个符号链接\n")
    elif args.verbose:
        print("未发现符号链接\n")

hpp_files = sorted(src_dir.rglob("*.hpp"))
if not hpp_files:
    if not args.clean:
        print("未找到任何 .hpp 文件。")
    sys.exit(0)

names = [f.name for f in hpp_files]
dupes = {k for k, v in Counter(names).items() if v > 1}
if dupes:
    print("⚠ 发现同名 .hpp 文件，将只链接第一个：")
    for name in dupes:
        print(f"  {name}:")
        for f in hpp_files:
            if f.name == name:
                print(f"    - {f}")
    print()

seen = set()
linked = 0
skipped = 0
failed = 0

for src in hpp_files:
    name = src.name
    dest = default_target / Path(name).stem

    if name in seen:
        if args.verbose:
            print(f"[跳过] {src} (同名文件已链接)")
        skipped += 1
        continue

    if dest.exists() or dest.is_symlink():
        if args.dry_run:
            print(f"[dry-run] 将删除: {dest}")
        else:
            try:
                dest.unlink()
                if args.verbose:
                    print(f"[删除] {dest}")
            except OSError as e:
                print(f"[失败] 无法删除 {dest}: {e}")
                skipped += 1
                continue

    if args.dry_run:
        print(f"[dry-run] 将链接: {src} -> {dest}")
    else:
        try:
            os.symlink(src, dest)
            if args.verbose:
                print(f"[链接] {src} -> {dest}")
        except OSError as e:
            print(f"[失败] 无法链接 {src} -> {dest}: {e}")
            failed += 1
            continue

    seen.add(name)
    linked += 1

print()
print(f"已链接: {linked}   跳过: {skipped}   失败: {failed}")
