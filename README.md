# Osmosis launcher
Osmosis launcher is an improvement of osmosis that allow osmosisd to run as a launcher adn receive commands later.

# Steps
## Clone source
Clone source from official github repository :
https://github.com/osmosis-labs/osmosis.git
## Modify code
Modify original cmd/osmosisd/main.go file to insert launcher code
https://github.com/osmosis-labs/osmosis/blob/main/cmd/osmosisd/main.go
## Build
Build the source using official
https://docs.osmosis.zone/osmosis-core/build
# Scripts
## osmosis.clone.sh
### Description
Used to clone osmosis, from official github repository, in osmosis directory

### Usage
```console
osmosis.clone.sh tag
```
Exemple :
```console
osmosis.clone.sh v12.3.0
```
### Dependencies
git
git-lfs
go  
## osmosisd-launcher.build.sh
### Description
Used to modify osmosis sources to include hability tu run as a launcher.
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

