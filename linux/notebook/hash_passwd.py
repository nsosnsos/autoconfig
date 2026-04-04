#!/usr/bin/env python3
# -*- coding:utf-8 -*-


import os
import sys
import getpass
from jupyter_server.auth import passwd


def help():
    filename = os.path.basename(__file__)
    print("Usage: {} [PASSWORD]".format(filename))
    print("       The password will be hashed using  SHA-256.")
    print("       If no password provided, will prompt securely.")

def hash_password(s):
    hashed_passwd = passwd(passphrase=s, algorithm='sha256')
    print(hashed_passwd)

if __name__ == '__main__':
    if len(sys.argv) == 2:
        password = sys.argv[1]
    elif len(sys.argv) == 1:
        password = getpass.getpass("Enter password to hash: ")
    else:
        help()
        sys.exit(-1)
    hash_password(password)

