#!/usr/bin/env python
import os
import shutil
import sys


def batch_move_files(source_dir, target_dir, suffix=None):

    if not os.path.isdir(source_dir):
        print(f"错误：源目录 {source_dir} 不存在")
        return

    if not os.path.exists(target_dir):
        os.makedirs(target_dir)
        print(f"已创建目标目录：{target_dir}")

    moved_count = 0

    for filename in os.listdir(source_dir):
        source_file = os.path.join(source_dir, filename)

        if not os.path.isfile(source_file):
            continue

        if suffix and not filename.endswith(suffix):
            continue

        target_file = os.path.join(target_dir, filename)

        if os.path.exists(target_file):
            name, ext = os.path.splitext(filename)
            count = 1
            while os.path.exists(os.path.join(target_dir, f"{name}_{count}{ext}")):
                count += 1
            target_file = os.path.join(target_dir, f"{name}_{count}{ext}")
            print(f"文件 {filename} 已存在，重命名为：{os.path.basename(target_file)}")

        shutil.move(source_file, target_file)
        moved_count += 1

    print(f"\n批量移动完成！共成功移动 {moved_count} 个文件")


if __name__ == "__main__":

    if len(sys.argv) < 3:
        print("用法说明：")
        print("  move <源目录路径> <目标目录路径> [可选：文件后缀（如 .txt）]")
        print("示例：")
        print("Win  :  move C:\\Users\\test\\Desktop D:\\txt_backup .txt")
        print("Linux:  move /home/user/docs /home/user/backup .pdf")
        sys.exit(1)

    source_dir = sys.argv[1]
    target_dir = sys.argv[2]
    suffix = sys.argv[3] if len(sys.argv) >= 4 else None

    batch_move_files(source_dir, target_dir, suffix)
