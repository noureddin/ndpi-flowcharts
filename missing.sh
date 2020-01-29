#!/bin/bash
grep -Po '(?<=xlink:href=")[^"]+' *html -h | sort -u |
    while read f; do
        if [ ! -e "$f" ]; then
            printf "%s\n" "${f%.html}"
        fi
    done
