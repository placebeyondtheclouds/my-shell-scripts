#!/bin/bash

ARCHIVE_DESTINATION=${1:-.}

for base in $(ls *.tar.gz.* | sed 's/\.[^.]*$//' | sort -u); do
    echo "转换ing all parts of $base"
    zcat ${base}.* >$ARCHIVE_DESTINATION/${base%.tar.gz}.tar
done
