#!/usr/bin/env python3
# -*- coding:utf-8 -*-

import re
import os
import sys


def remove_trailing_spaces(file_name):
    with open(file_name, mode="r+", encoding='utf8', errors='ignore', newline='') as file:
        text = file.read()
        text = re.sub(r'[ \t]+(\n|\Z)', r'\1', text)
        file.seek(0)
        file.write(text)
        file.truncate()


def recursive_process(file_path, ext_list):
    if not os.path.exists(file_path):
        return
    elif not os.path.isdir(file_path):
        remove_trailing_spaces(file_path)
        return
    for file in os.listdir(file_path):
        if file not in ext_list and os.path.splitext(os.path.basename(file))[1] not in ext_list:
            cur_file = os.path.join(file_path, file)
            if os.path.isdir(cur_file):
                recursive_process(cur_file, ext_list)
            else:
                remove_trailing_spaces(cur_file)


if __name__ == '__main__':
    if len(sys.argv) <= 1:
        print("Usage: "+os.path.basename(__file__)+"dos2unix file_path [ext_list]")
        sys.exit(-1)
    exclude_list = []
    if len(sys.argv) > 2:
        exclude_list.extend(sys.argv[2].split(","))
    recursive_process(sys.argv[1], exclude_list)
