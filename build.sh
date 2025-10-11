#! /usr/bin/bash

if [[ -e kobo ]]; then
    rm kobo
fi

if  [[ $# > 0 && $1 == "debug" ]]; then
    odin build src/ -collection:kobold=src -vet -strict-style -out:kobo -debug
else
    odin build src/ -collection:kobold=src -vet -strict-style -out:kobo
fi
