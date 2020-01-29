#!/bin/bash

make

declare -A mt

for f in dpi dpi/*; do mt[$f]="$(stat "$f" -c%Y)"; done

while sleep 1; do
    for f in dpi dpi/*; do
        if [ -z "${mt[$f]}" ]; then
            mt[$f]="$(stat "$f" -c%Y)"
        else
            if [ "${mt[$f]}" -ne "$(stat "$f" -c%Y)" ]; then
                make
                for f in dpi dpi/*; do mt[$f]="$(stat "$f" -c%Y)"; done
                break
            fi
        fi
    done
done
