#!/usr/bin/env bash

set -e
set -x

cd ompi
git fetch origin
git branch -b huawei v4.0.3
git push origin huawei
cd ..

cd ucx
git fetch origin
git branch -b huawei v1.6.0
git push origin huawei
cd ..

cd xucg
git fetch origin
git checkout -b huawei origin/master
git push origin huawei
cd ..
