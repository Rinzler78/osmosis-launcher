#!/bin/bash

version="v12.3.0"

if ! ./patch.sh $version
then
    echo "Cannot build osmosis-launcher"
    exit 1
fi

# Build osmosisd
echo "Building osmosis"
if make build -C osmosis
then
    targetOsmosisdFile=osmosisd
    if [[ -f $targetOsmosisdFile ]]
    then
        echo "Removing $targetOsmosisdFile"
        rm $targetOsmosisdFile
    fi

    # Copy generated binary
    cp osmosis/build/osmosisd $targetOsmosisdFile

    # Show version
    if ./$targetOsmosisdFile --launcher version
    then
        echo "It works !!"
    else
        echo "Seems does not work"
        exit 1
    fi
else
    echo "Build failed"
    exit 1
fi

rm -rf osmosis