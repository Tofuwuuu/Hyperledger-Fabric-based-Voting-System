#!/bin/bash

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# Print the usage message
function printHelp() {
    USAGE="$1"
    if [ "$USAGE" == "up" ]; then
        println "Usage: "
        println "  network.sh up [-ca] [-c <channel name>] [-s <dbtype>] [-r <max retry>] [-d <delay>] [-verbose]"
        println "  network.sh up -h (print this message)"
        println
        println "    -ca: Use Certificate Authorities"
        println "    -c <channel name>: Name of channel to create (defaults to \"votingchannel\")"
        println "    -s <dbtype>: Database type (\"goleveldb\" or \"couchdb\") (default \"goleveldb\")"
        println "    -r <max retry>: Maximum retry attempts for network operations (default 5)"
        println "    -d <delay>: Delay between retry attempts (default 3)"
        println "    -verbose: Enable verbose mode"
    elif [ "$USAGE" == "createChannel" ]; then
        println "Usage: "
        println "  network.sh createChannel [-c <channel name>] [-r <max retry>] [-d <delay>] [-verbose]"
        println "  network.sh createChannel -h (print this message)"
        println
        println "    -c <channel name>: Name of channel to create (defaults to \"votingchannel\")"
        println "    -r <max retry>: Maximum retry attempts for network operations (default 5)"
        println "    -d <delay>: Delay between retry attempts (default 3)"
        println "    -verbose: Enable verbose mode"
    elif [ "$USAGE" == "deployCC" ]; then
        println "Usage: "
        println "  network.sh deployCC [-c <channel name>] [-ccn <name>] [-ccl <language>] [-ccv <version>] [-ccs <sequence>]"
        println "  network.sh deployCC -h (print this message)"
        println
        println "    -c <channel name>: Name of channel (defaults to \"votingchannel\")"
        println "    -ccn <name>: Name of chaincode (defaults to \"votingcc\")"
        println "    -ccl <language>: Programming language of chaincode (\"go\", \"java\", \"javascript\") (default \"go\")"
        println "    -ccv <version>: Version of chaincode (defaults to \"1.0\")"
        println "    -ccs <sequence>: Sequence number of chaincode (defaults to \"1\")"
        println "    -verbose: Enable verbose mode"
    else
        println "Usage: "
        println "  network.sh <mode> [-c <channel name>] [-ca] [-s <dbtype>] [-r <max retry>] [-d <delay>] [-verbose]"
        println "    Modes:"
        println "      up - Bring up Fabric orderer and peer nodes. No channel is created"
        println "      down - Bring down running Fabric orderer and peer nodes"
        println "      createChannel - Create and join a channel after the network is created"
        println "      deployCC - Deploy chaincode"
        println
        println "    -h: Print this message"
    fi
}

# println echos string
function println() {
    echo -e "$1"
}

# errorln echos i red color
function errorln() {
    println "${C_RED}${1}${C_RESET}"
}

# successln echos in green color
function successln() {
    println "${C_GREEN}${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
    println "${C_BLUE}${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
    println "${C_YELLOW}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
    errorln "$1"
    exit 1
}

export -f errorln
export -f successln
export -f infoln
export -f warnln