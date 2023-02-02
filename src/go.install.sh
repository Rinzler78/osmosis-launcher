#!/bin/bash

osmosis_version=$(./version.resolve.sh $1)

if ! ./go.isInstalled.sh $osmosis_version
then
    requiered_goland_version=$(./go.requieredVersion.sh $osmosis_version)
    echo "Need to install goland => $requiered_goland_version"

    tar_file="$requiered_goland_version.$(echo "$(uname)" | tr '[:upper:]' '[:lower:]')-amd64.tar.gz"
    wget "https://go.dev/dl/$tar_file"
    tar -zxf "$tar_file"
    sudo rm -rf /usr/local/go ~/go ~/.go
    sudo mv go /usr/local/
    rm $tar_file

    mkdir ~/go ~/.go
fi

installed_goland_version=$(go version | cut -d " " -f 3)
echo "goland $installed_goland_version installed"