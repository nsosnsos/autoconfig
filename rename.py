#!/usr/bin/env python3

import io
import os
import sys


def rename_traverse_dir(dir_name, old_suffix, new_suffix):
    if not os.path.exists(dir_name):
        return
    files = os.listdir(dir_name)
    for f in files:
        cur_file = os.path.join(dir_name, f)
        if os.path.isdir(cur_file):
            rename_traverse_dir(cur_file, old_suffix, new_suffix)
        elif old_suffix:
            if cur_file.endwith(old_suffix):
                file_name, file_ext = os.path.splitext(cur_file)
                os.rename(cur_file, file_name + "." + new_suffix)
        else:
            os.rename(cur_file, cur_file + "." + new_suffix)

if __name__ == "__main__":
    if len(sys.argv) < 3 or len(sys.argv) > 4  or not os.path.isdir(sys.argv[1]):
        print("Usage: rename DIR_NAME [OLD_SUFFIX] NEW_SUFFIX")
        sys.exit(-1)
    if len(sys.argv) == 3:
        rename_traverse_dir(sys.argv[1], None, sys.argv[2])
    else:
        rename_traverse_dir(sys.argv[1], sys.argv[2], sys.argv[3])

