#!/bin/bash

gitHubRepoUrl="https://github.com/osmosis-labs/osmosis.git"
version=$(./version.resolve.sh $1)
targetFolder="osmosis"

if ! command -v git &> /dev/null
then
    echo "git not installed"
    exit 1
fi

if [[ -d "$targetFolder" ]]
then
    echo "Removing $targetFolder"
    rm -rf $targetFolder
fi

echo "Cloning tag $version @ $gitHubRepoUrl"
if ! git clone $gitHubRepoUrl --branch $version --single-branch $targetFolder
then
    echo "git clone $gitHubRepoUrl --branch $version --single-branch $targetFolder clone failed"
    exit 1
fi


