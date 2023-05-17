#!/bin/bash

version=$1

if [ "$version" != "v15.1.0" ];
then
    version="v15.1.0"
fi

echo $version