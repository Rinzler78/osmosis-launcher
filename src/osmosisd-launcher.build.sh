#!/bin/bash

version="v12.3.0"

if ! ./osmosis.clone.sh $version
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