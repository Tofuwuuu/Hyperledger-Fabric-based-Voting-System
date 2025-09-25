#!/bin/bash

. scripts/utils.sh

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

# Initialize the network
function networkUp() {
    if [ ! -d "organizations/peerOrganizations" ]; then
        createOrgs
    fi

    COMPOSE_FILES="-f ${DOCKER_COMPOSE_FILE_BASE}"

    if [ "${DATABASE}" == "couchdb" ]; then
        COMPOSE_FILES="${COMPOSE_FILES} -f ${DOCKER_COMPOSE_FILE_COUCH}"
    fi

    DOCKER_SOCK="${DOCKER_SOCK}" docker-compose ${COMPOSE_FILES} up -d 2>&1

    docker ps -a
    if [ $? -ne 0 ]; then
        fatalln "Unable to start network"
    fi
}

# Create Channel
function createChannel() {
    scripts/createChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE
}

# Deploy chaincode
function deployCC() {
    scripts/deployCC.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE

    if [ $? -ne 0 ]; then
        fatalln "Deploying chaincode failed"
    fi
}

# Bring the network down
function networkDown() {
    docker-compose -f $DOCKER_COMPOSE_FILE_BASE -f $DOCKER_COMPOSE_FILE_COUCH down --volumes --remove-orphans
    if [ "$MODE" != "restart" ]; then
        docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/peerOrganizations organizations/ordererOrganizations'
        docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/electioncommission organizations/fabric-ca/auditor organizations/fabric-ca/ordererOrg'
    fi
}

# Parse commandline args
MODE=$1
shift

while [[ $# -gt 0 ]]; do
    case "$1" in
    -h)
        printHelp
        exit 0
        ;;
    -c)
        CHANNEL_NAME="$2"
        shift
        ;;
    -ca)
        CRYPTO="Certificate Authorities"
        ;;
    -r)
        MAX_RETRY="$2"
        shift
        ;;
    -d)
        CLI_DELAY="$2"
        shift
        ;;
    -s)
        DATABASE="$2"
        shift
        ;;
    -ccl)
        CC_SRC_LANGUAGE="$2"
        shift
        ;;
    -ccn)
        CC_NAME="$2"
        shift
        ;;
    -ccp)
        CC_SRC_PATH="$2"
        shift
        ;;
    -ccv)
        CC_VERSION="$2"
        shift
        ;;
    -ccs)
        CC_SEQUENCE="$2"
        shift
        ;;
    -cci)
        CC_INIT_FCN="$2"
        shift
        ;;
    -ccep)
        CC_END_POLICY="$2"
        shift
        ;;
    -cccg)
        CC_COLL_CONFIG="$2"
        shift
        ;;
    -verbose)
        VERBOSE=true
        ;;
    *)
        errorln "Unknown flag: $1"
        printHelp
        exit 1
        ;;
    esac
    shift
done

# Are we generating crypto material with this command?
if [ ! -d "organizations/peerOrganizations" ]; then
    CRYPTO_MODE="with crypto from '${CRYPTO}'"
else
    CRYPTO_MODE=""
fi

# Process mode
if [ "$MODE" == "up" ]; then
    networkUp
elif [ "$MODE" == "createChannel" ]; then
    createChannel
elif [ "$MODE" == "deployCC" ]; then
    deployCC
elif [ "$MODE" == "down" ]; then
    networkDown
else
    printHelp
    exit 1
fi