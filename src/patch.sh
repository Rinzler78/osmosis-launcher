#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$1"
LAUNCHER_GO_SRC="$SCRIPT_DIR/launcher.go"

# Check if TARGET_DIR exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "[FAIL] Target directory $TARGET_DIR does not exist."
    exit 1
fi

mainFilePath="$TARGET_DIR/cmd/osmosisd/main.go"
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
cp "$LAUNCHER_GO_SRC" "$TARGET_DIR/cmd/osmosisd/"

## Insert wait for launcher function
rootCmdLine="cmd.NewRootCmd()"
waitForLauncherFunctionCall="wait_for_launcher()"
newCodeLine="$rootCmdLine\n\t$waitForLauncherFunctionCall"
mainGoFile="${mainGoFile/$rootCmdLine/$newCodeLine}"

# Write new code
echo -e "$mainGoFile" > $mainFilePath