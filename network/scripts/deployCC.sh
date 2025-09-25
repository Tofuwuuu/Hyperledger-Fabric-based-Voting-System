#!/bin/bash

. scripts/utils.sh

CHANNEL_NAME=${1:-"votingchannel"}
CC_NAME=${2:-"votingcc"}
CC_SRC_PATH=${3:-"../chaincode/voting"}
CC_SRC_LANGUAGE=${4:-"go"}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}
CC_INIT_FCN=${7:-"InitLedger"}
CC_END_POLICY=${8:-"NA"}
CC_COLL_CONFIG=${9:-"NA"}
DELAY=${10:-"3"}
MAX_RETRY=${11:-"5"}
VERBOSE=${12:-"false"}

FABRIC_CFG_PATH=$PWD/config/

packageChaincode() {
    set -x
    peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_SRC_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Chaincode packaging has failed"
    successln "Chaincode is packaged"
}

installChaincode() {
    ORG=$1
    setGlobals $ORG
    set -x
    peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Chaincode installation on peer0.${ORG} has failed"
    successln "Chaincode is installed on peer0.${ORG}"
}

queryInstalled() {
    ORG=$1
    setGlobals $ORG
    set -x
    peer lifecycle chaincode queryinstalled >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    verifyResult $res "Query installed on peer0.${ORG} has failed"
    successln "Query installed successful on peer0.${ORG} on channel"
}

approveForMyOrg() {
    ORG=$1
    setGlobals $ORG
    set -x
    peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Chaincode definition approved on peer0.${ORG} on channel '$CHANNEL_NAME' failed"
    successln "Chaincode definition approved on peer0.${ORG} on channel '$CHANNEL_NAME'"
}

checkCommitReadiness() {
    ORG=$1
    setGlobals $ORG
    infoln "Checking the commit readiness of the chaincode definition on peer0.${ORG} on channel '$CHANNEL_NAME'..."
    local rc=1
    local COUNTER=1
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        infoln "Attempting to check the commit readiness of the chaincode definition on peer0.${ORG}, Retry after $DELAY seconds."
        set -x
        peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
        res=$?
        { set +x; } 2>/dev/null
        let rc=0
        for var in "$@"; do
            grep "$var" log.txt &>/dev/null || let rc=1
        done
        COUNTER=$(expr $COUNTER + 1)
    done
    cat log.txt
    if [ $rc -eq 0 ]; then
        infoln "Checking the commit readiness of the chaincode definition successful on peer0.${ORG} on channel '$CHANNEL_NAME'"
    else
        fatalln "After $MAX_RETRY attempts, Check commit readiness result on peer0.${ORG} is INVALID!"
    fi
}

commitChaincodeDefinition() {
    parsePeerConnectionParameters $@
    res=$?
    verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

    set -x
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    verifyResult $res "Chaincode definition commit failed on peer0.${ORG} on channel '$CHANNEL_NAME' failed"
    successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

queryCommitted() {
    ORG=$1
    setGlobals $ORG
    EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
    infoln "Querying chaincode definition on peer0.${ORG} on channel '$CHANNEL_NAME'..."
    local rc=1
    local COUNTER=1
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        infoln "Attempting to Query committed status on peer0.${ORG}, Retry after $DELAY seconds."
        set -x
        peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
        res=$?
        { set +x; } 2>/dev/null
        test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
        test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
        COUNTER=$(expr $COUNTER + 1)
    done
    cat log.txt
    if [ $rc -eq 0 ]; then
        successln "Query chaincode definition successful on peer0.${ORG} on channel '$CHANNEL_NAME'"
    else
        fatalln "After $MAX_RETRY attempts, Query chaincode definition result on peer0.${ORG} is INVALID!"
    fi
}

chaincodeInvokeInit() {
    parsePeerConnectionParameters $@
    res=$?
    verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

    set -x
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'
    infoln "invoke fcn call:${fcn_call}"
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS --isInit -c ${fcn_call} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Invoke execution on $PEERS failed "
    successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

## Package the chaincode
packageChaincode

## Install chaincode on peer0.org1 and peer0.org2
infoln "Installing chaincode on peer0.ElectionCommission..."
installChaincode ElectionCommission
infoln "Installing chaincode on peer0.Auditor..."
installChaincode Auditor

## Query whether the chaincode is installed
queryInstalled ElectionCommission

## Approve the definition for org1
approveForMyOrg ElectionCommission

## Check whether org1 has approved
checkCommitReadiness ElectionCommission "\"ElectionCommissionMSP\": true" "\"AuditorMSP\": false"
checkCommitReadiness Auditor "\"ElectionCommissionMSP\": true" "\"AuditorMSP\": false"

## Now approve for org2
approveForMyOrg Auditor

## Check whether org2 has approved
checkCommitReadiness ElectionCommission "\"ElectionCommissionMSP\": true" "\"AuditorMSP\": true"
checkCommitReadiness Auditor "\"ElectionCommissionMSP\": true" "\"AuditorMSP\": true"

## Commit the definition
commitChaincodeDefinition ElectionCommission Auditor

## Query on both orgs to see that the definition committed successfully
queryCommitted ElectionCommission
queryCommitted Auditor

## Invoke the chaincode - this does require that the chaincode have the 'InitLedger' method
if [ "$CC_INIT_FCN" = "InitLedger" ]; then
    chaincodeInvokeInit ElectionCommission Auditor
else
    infoln "Skipping chaincode initialization as no InitLedger function was requested"
fi