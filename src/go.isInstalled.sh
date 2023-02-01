#!/bin/bash

osmosis_version=$(./version.resolve.sh $1)
requiered_goland_version=$(./go.requieredVersion.sh $osmosis_version)
installed_goland_version=$(go version | cut -d " " -f 3)

if ! [ "$requiered_goland_version" == "$installed_goland_version" ];
then
    exit 1
fi

exit 0