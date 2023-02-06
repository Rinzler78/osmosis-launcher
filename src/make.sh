#!/bin/bash

version=$(./version.resolve.sh $1)

if ! ./go.install.sh $version
then
    echo "goland installation failed"
    exit 1
fi

if ! ./patch.sh $version
then
    echo "Cannot build osmosis-launcher"
    exit 1
fi

if ! command -v make &> /dev/null
then
    sudo apt-get install -y build-essential
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