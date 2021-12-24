#!/usr/bin/env python3
# -*- coding:utf-8 -*-

import io
import os
import sys


def traverse_dir(dir_name):
    r = []
    if not os.path.exists(dir_name):
        return
    files = os.listdir(dir_name)
    for f in files:
        cur_file = os.path.join(dir_name, f)
        if os.path.isdir(cur_file):
            r.extend(traverse_dir(cur_file))
        else:
            r.append(cur_file)
    return r

if __name__ == "__main__":
    if len(sys.argv) < 2 or not os.path.isdir(sys.argv[1]):
        print("Usage: listdir DIR_NAME")
        sys.exit(-1)
    r = traverse_dir(sys.argv[1])
    with io.open(os.path.join(os.path.dirname(sys.argv[1]), "result.txt"), 'w', encoding='utf-8') as f:
        for i in range(len(r)):
            f.write(r[i][len(sys.argv[1]):])
            f.write("\n")
