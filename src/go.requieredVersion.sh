#!/bin/bash

osmosis_version=$(./version.resolve.sh $1)
requiered_goland_version=""

# Dependencies
if [ "$osmosis_version" == "v12.3.0" ];
then
    echo "go1.18.1"
    exit 0
elif [ "$osmosis_version" == "v14.0.0" ];
then
    echo "go1.19"
    exit 0
fi

exit 1