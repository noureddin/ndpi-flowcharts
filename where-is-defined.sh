#!/bin/bash
tags='../nDPI/example/tags'
for i in ${@:-$(./missing.sh|sort)}; do
    grep $i "$tags"
done | cut -f -2 | column -t -s$'\t'
