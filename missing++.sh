#!/bin/bash
htmlroot='../noureddin.github.io/ndpi-flowcharts/'
grep -Po '(?<=xlink:href=")[^"]+' $htmlroot*html | sort -u |
    while read result; do
        containing="${result%:*}"
        containing="${containing##*/}"
        linked="${result#*:}"
        if [ ! -e "$htmlroot$linked" ]; then
            printf "%s (%s)\n" "${linked%.html}" "$containing"
        fi
    done | sort | column -t -s' '
