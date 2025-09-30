#!/bin/bash

. scripts/utils.sh

# Default values
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false
export DOCKER_COMPOSE_FILE_BASE=docker-compose.yaml
export DOCKER_COMPOSE_FILE_COUCH=docker-compose-couch.yaml
export CHANNEL_NAME="votingchannel"
export CORE_PEER_TLS_ENABLED=true
export CLI_DELAY=3
export MAX_RETRY=5
export CC_NAME="votingcc"
export CC_SRC_PATH="../chaincode/voting"
export CC_SRC_LANGUAGE="go"
export CC_VERSION="1.0"
export CC_SEQUENCE="1"
export CC_INIT_FCN="InitLedger"
export CC_END_POLICY="OR('ElectionCommissionMSP.peer','AuditorMSP.peer')"
export CC_COLL_CONFIG="../chaincode/voting/collections_config.json"
export DATABASE="couchdb"

# OS specific commands
if [[ "$OSTYPE" == "darwin"* ]]; then
    export SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
    export DOCKER_SOCK="${SOCK##unix://}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
    export DOCKER_SOCK="${SOCK##unix://}"
else
    # Windows specific settings
    export MSYS_NO_PATHCONV=1
    export DOCKER_SOCK=
fi

# Initialize the network
function networkUp() {
    # Create crypto material using cryptogen or fabric-ca
    if [ ! -d "organizations/peerOrganizations" ]; then
        if [ "$CRYPTO" == "Certificate Authorities" ]; then
            infoln "Generating certificates using Fabric CA"
            createOrgsUsingCA
        else
            infoln "Generating certificates using cryptogen"
            createOrgs
        fi
    fi

    # Check if chaincode name is provided
    if [ "$CC_NAME" = "" ]; then
        fatalln "No chaincode name provided"
    fi

    COMPOSE_FILES="-f ${DOCKER_COMPOSE_FILE_BASE}"
    if [ "${DATABASE}" == "couchdb" ]; then
        COMPOSE_FILES="${COMPOSE_FILES} -f ${DOCKER_COMPOSE_FILE_COUCH}"
    fi

    DOCKER_SOCK="${DOCKER_SOCK}" docker compose ${COMPOSE_FILES} up -d 2>&1 || DOCKER_SOCK="${DOCKER_SOCK}" docker-compose ${COMPOSE_FILES} up -d 2>&1

    docker ps -a
    if [ $? -ne 0 ]; then
        fatalln "Unable to start network"
    fi

    # Wait for containers to be ready
    sleep 5

    # Initialize the CouchDB indices if using CouchDB
    if [ "${DATABASE}" == "couchdb" ]; then
        initCouchDBIndices
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
    infoln "Stopping network"
    set -x
    if [ "${CONTAINER_CLI}" == "docker" ]; then
        DOCKER_SOCK=$DOCKER_SOCK ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} down --volumes --remove-orphans
    else
        ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} down --volumes
    fi
    
    # Remove containers
    ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
    
    # Remove fabric chaincode containers
    ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter name='dev-peer*') 2>/dev/null || true
    
    # Remove fabric chaincode images
    ${CONTAINER_CLI} rmi $(${CONTAINER_CLI} images -aq --filter reference='dev-peer*') 2>/dev/null || true
    
    # Don't remove the generated artifacts -- note, the ledgers are always removed
    if [ "$MODE" != "restart" ]; then
        # Cleanup the chaincode containers
        clearContainers
        # Cleanup images
        removeUnwantedImages
        # remove orderer block and other channel configuration transactions and certs
        ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'
        ## remove fabric ca artifacts
        ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org1/msp organizations/fabric-ca/org1/tls-cert.pem organizations/fabric-ca/org1/ca-cert.pem organizations/fabric-ca/org1/IssuerPublicKey organizations/fabric-ca/org1/IssuerRevocationPublicKey organizations/fabric-ca/org1/fabric-ca-server.db'
        ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org2/msp organizations/fabric-ca/org2/tls-cert.pem organizations/fabric-ca/org2/ca-cert.pem organizations/fabric-ca/org2/IssuerPublicKey organizations/fabric-ca/org2/IssuerRevocationPublicKey organizations/fabric-ca/org2/fabric-ca-server.db'
        ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
        ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf addOrg3/fabric-ca/org3/msp addOrg3/fabric-ca/org3/tls-cert.pem addOrg3/fabric-ca/org3/ca-cert.pem addOrg3/fabric-ca/org3/IssuerPublicKey addOrg3/fabric-ca/org3/IssuerRevocationPublicKey addOrg3/fabric-ca/org3/fabric-ca-server.db'
        # remove channel and script artifacts
        ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'
    fi
    
    set +x
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