#!/usr/bin/env python3
# -*- coding:utf-8 -*-


import os
import sys
from jupyter_server.auth import passwd


def help():
    filename = os.path.basename(__file__)
    print("Usage: {} PASSWORD".format(filename))
    print("       the password will be hashed using  SHA-256.")

def hash_password(s):
    hashed_passwd = passwd(passphrase=s, algorithm='sha256')
    print(hashed_passwd)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        help()
        sys.exit(-1)
    hash_password(sys.argv[1])

