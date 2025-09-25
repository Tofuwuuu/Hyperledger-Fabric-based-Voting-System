#!/bin/bash

. scripts/utils.sh

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"

createChannelGenesisBlock() {
    infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
    set -x
    configtxgen -profile TwoOrgsChannel -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
        fatalln "Failed to generate channel configuration transaction..."
    fi
}

createChannel() {
    setGlobals 'ElectionCommission'
    # Poll in case the raft leader is not set yet
    local rc=1
    local COUNTER=1
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        infoln "Creating channel ${CHANNEL_NAME}, try $COUNTER"
        set -x
        peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.example.com -f ./channel-artifacts/${CHANNEL_NAME}.block --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA >&log.txt
        res=$?
        { set +x; } 2>/dev/null
        let rc=$res
        COUNTER=$(expr $COUNTER + 1)
    done
    cat log.txt
    verifyResult $res "Channel creation failed"
    successln "Channel '$CHANNEL_NAME' created"
}

# joinChannel ORG
joinChannel() {
    FABRIC_CFG_PATH=$PWD/config/
    ORG=$1
    setGlobals $ORG
    local rc=1
    local COUNTER=1
    ## Sometimes Join takes time, hence retry
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        set -x
        peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
        res=$?
        { set +x; } 2>/dev/null
        let rc=$res
        COUNTER=$(expr $COUNTER + 1)
    done
    cat log.txt
    verifyResult $res "After $MAX_RETRY attempts, peer0.${ORG} has failed to join channel '$CHANNEL_NAME'"
}

setAnchorPeer() {
    ORG=$1
    docker exec cli ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME
}

FABRIC_CFG_PATH=${PWD}/configtx

## Create channel genesis block
createChannelGenesisBlock

## Create channel
createChannel

## Join all the peers to the channel
infoln "Joining ElectionCommission peer to the channel..."
joinChannel ElectionCommission
infoln "Joining Auditor peer to the channel..."
joinChannel Auditor

## Set the anchor peers for each org in the channel
infoln "Setting anchor peer for ElectionCommission..."
setAnchorPeer ElectionCommission
infoln "Setting anchor peer for Auditor..."
setAnchorPeer Auditor

successln "Channel '$CHANNEL_NAME' joined"