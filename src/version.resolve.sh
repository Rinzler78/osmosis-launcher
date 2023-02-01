#!/bin/bash

version=$1

if [ "$version" != "v12.3.0" ] && [ "$version" != "v14.0.0" ];
then
    version="v12.3.0"
fi

echo $version