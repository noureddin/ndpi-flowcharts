#!/bin/bash
htmlroot='../noureddin.github.io/ndpi-flowcharts/'
grep -Po '(?<=xlink:href=")[^"]+' $htmlroot*html -h | sort -u |
    while read f; do
        if [ ! -e "$htmlroot$f" ]; then
            printf "%s\n" "${f%.html}"
        fi
    done
