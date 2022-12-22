# Osmosis launcher
Osmosis launcher is an improvement of osmosis that allow osmosisd to run as a launcher adn receive commands later.

# Quick start
## Make
Call make.sh in src directory
```console
./make.sh
```
## Use
Call osmosid with "--launcher" argument :
```console
./osmosid --launcher
```

And write command to execute.
Exemple : version

# Steps
## Clone
Clone source from official github repository :
https://github.com/osmosis-labs/osmosis.git
## Patch
Patch original cmd/osmosisd/main.go file to insert launcher code
https://github.com/osmosis-labs/osmosis/blob/main/cmd/osmosisd/main.go
## Make
Make the source using official
https://docs.osmosis.zone/osmosis-core/make
# Scripts
## clone.sh
### Description
Used to clone osmosis, from official github repository, in osmosis directory

### Usage
```console
clone.sh tag
```
Exemple :
```console
clone.sh v12.3.0
```
### Dependencies
git
git-lfs
go  

## patch.sh
### Description
Used to patch osmosis sources to include hability tu run as a launcher.
### Usage
```console
patch.sh tag
```
Exemple :
```console
patch.sh v12.3.0
```
## make.sh
### Description
Used to make osmosis sources
### Usage
#### Run as launcher :
In this case osmosisd will start and wait fo entry in stdIn
```console
osmosisd --launcher
```
#### Run as launcher but passing other commands now :
In this case osmosisd will start and immediately run commands other commands
```console
osmosisd --launcher optionnalArg1 optionnalArg2 ...
```

It similare to :
```console
osmosisd optionnalArg1 optionnalArg2 ...
```

## launcher.go
### Description
Contains code allowing osmosisd to catch "--launcher" command line argument.

