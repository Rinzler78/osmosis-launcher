#!/bin/bash

version=$1

if ! ./clone.sh $version
then
    echo "Cannot build osmosis-launcher"
    exit 1
fi

mainFilePath="osmosis/cmd/osmosisd/main.go"
mainFileBaseDirectory=${mainFilePath%/*}

if ! [[ -f $mainFilePath ]]
then
    echo "$mainFilePath not exists"
    exit 1 
fi

mainGoFile="$(cat $mainFilePath)"
launcherGoFilePath="launcher.go"
targetLauncherGoFile="$mainFileBaseDirectory/$launcherGoFilePath"

if [[ -f $targetLauncherGoFile ]]
then
    echo "Remove $targetLauncherGoFile"
    rm -rf $targetLauncherGoFile
fi

# Copy launcher go file to cmd/osmosisd directory
cp $launcherGoFilePath $targetLauncherGoFile

## Insert wait for launcher function
rootCmdLine="cmd.NewRootCmd()"
waitForLauncherFunctionCall="wait_for_launcher()"
newCodeLine="$rootCmdLine\n\t$waitForLauncherFunctionCall"
mainGoFile="${mainGoFile/$rootCmdLine/$newCodeLine}"

# Write new code
echo -e "$mainGoFile" > $mainFilePath