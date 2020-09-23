# !/usr/bin/env python
# -*- coding:utf-8 -*-

import re
import os
import sys


def dos2unix(file_name):
    with open(file_name, "r+", encoding='utf8', errors='ignore', newline='') as f:
        text = f.read()
        text = re.sub("\r\n", "\n", text)
        f.seek(0)
        f.write(text)
        f.truncate()


def recursive_process(file_path):
    if not os.path.exists(file_path):
        return
    elif not os.path.isdir(file_path):
        dos2unix(file_path)
        return
    files = os.listdir(file_path)
    for f in files:
        cur_file = os.path.join(file_path, f)
        if os.path.isdir(cur_file):
            recursive_process(cur_file)
        else:
            dos2unix(cur_file)


if __name__ == '__main__':
    if len(sys.argv) <= 1:
        print("Usage: dos2unix file_path")
    recursive_process(sys.argv[1])
