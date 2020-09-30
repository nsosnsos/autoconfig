#!/bin/bash

#USAGE: diffstat.sh [A] [B]

if [ ! $2 ]; then
    printf "\n    Usage: diffstat.sh A B\n\n"
    exit
fi

logfile=/tmp/diffstat.log

diff -Npur --exclude=".ci" --exclude=".git" --exclude=".github" --exclude="build" --exclude="lib" --exclude="contrib" --exclude="README*" --exclude=".gitignore" "$1" "$2" > "$logfile"
add_lines=`cat "$logfile" | grep ^+ | wc -l`
del_lines=`cat "$logfile" | grep ^- | wc -l`
at_lines=`cat "$logfile" | grep ^@ | wc -l`
all_lines=`cat "$logfile" | wc -l`
mod_lines=`expr $all_lines - $add_lines - $del_lines - $at_lines`
total_lines=`expr $mod_lines + $add_lines - 1 + $del_lines - 1`

printf "Total added lines:    %10s\n" "$add_lines"
printf "Total deleted lines:  %10s\n" "$del_lines"
printf "Total modified lines: %10s\n" "$mod_lines"
printf "Total changed lines:  %10s\n" "$total_lines"

:'
find ompi -name '*.inl' -o -name '*.h' -o -name '*.hxx' -o -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '.java' -o -name '*.sh' -o -name '*.am' -o -name '*.m4' | xargs wc -l | grep ' total'
 135670 total
  96859 total
 105553 total
  67517 total
 124808 total
 188882 total
 119429 total
 133196 total
 147681 total
  43341 total
find ucx -name '*.inl' -o -name '*.h' -o -name '*.hxx' -o -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '.java' -o -name '*.sh' -o -name '*.am' -o -name '*.m4' | xargs wc -l | grep ' total'
 224960 total

$ diff -Npur --exclude=".ci" --exclude=".git" --exclude=".github" --exclude="build" --exclude="lib" --exclude="contrib" --exclude="README*" ompi-4.0.3 ompi > ompi.patch
$ diff -Npur --exclude=".ci" --exclude=".git" --exclude=".github" --exclude="build" --exclude="lib" --exclude="contrib" --exclude="README*" --exclude=".gitignore" ucx-1.6.0 ucx > ucx.patch

$ ./diffstat.sh ompi-4.0.3 ompi
Total added lines:          1822
Total deleted lines:         599
Total modified lines:        212
Total changed lines:        2631


$ ./diffstat.sh ucx-1.6.0 ucx
Total added lines:          9697
Total deleted lines:         122
Total modified lines:        585
Total changed lines:       10402
'
