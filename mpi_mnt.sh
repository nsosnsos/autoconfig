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

### ADD SUBMODULE ###
cd ucx
git submodule add -b huawei --name xucg https://github.com/nsosnsos/xucg.git src/ucg

### FALLBACK EXAMPLE ###
cd ompi
# reset 1 commit
git reset --soft HEAD~1
# save reverted commit to patch
git stash show -p --color=never > ../hmpi.patch
# clean repository
git checkout . && git clean -f
# reset upstream 1 commit
git push --set-upstream origin huawei -f
