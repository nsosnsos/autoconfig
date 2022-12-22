#!/usr/bin/env python3
# -*- coding:utf-8 -*-

import os
import sys


def dos2unix(file_name):
    with open(file_name, "r+", encoding='utf8', errors='ignore', newline='') as file:
        text = file.read()
        text = re.sub("\r\n", "\n", text)
        file.seek(0)
        file.write(text)
        file.truncate()

def remove_trailing_spaces(file_name):
    with open(file_name, mode="r+", encoding='utf8', errors='ignore', newline='') as file:
        text = file.read()
        text = re.sub(r'[ \t]+(\n|\Z)', r'\1', text)
        file.seek(0)
        file.write(text)

def lower_ext(filename):
    prefix, ext = os.path.splitext(filename)
    if ext != ext.lower():
        newname = prefix + ext.lower()
        os.rename(filename, newname)

def dir_batch(dir_name, process_func):
    for root, dirs, files in os.walk(dir_name, topdown=False):
        for filename in files:
            full_filename = os.path.join(root, filename)
            process_func(full_filename)
        for dirname in dirs:
            pass

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f'Usage: {os.path.basename(__file__)} DIR_NAME')
        sys.exit(-1)
    dir_name = sys.argv[1]
    if not os.path.isdir(dir_name):
        print(f'{dir_name} is not a valid path!')
        sys.exit(-1)
    dir_batch(dir_name, lower_ext)

