#!/bin/bash

if [[ -d ./output ]]; then
        rm -rf ./output
fi

go build -tags netgo -a -v -o ./output/rest-endpoint
