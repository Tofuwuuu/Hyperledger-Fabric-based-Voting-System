#!/bin/bash

# Generate crypto material
cryptogen generate --config=./organizations/cryptogen/crypto-config-electioncommission.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-auditor.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"

# Create genesis block
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block

# Create channel transaction
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/votingchannel.tx -channelID votingchannel

# Create anchor peer transactions
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ElectionCommissionMSPanchors.tx -channelID votingchannel -asOrg ElectionCommissionMSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/AuditorMSPanchors.tx -channelID votingchannel -asOrg AuditorMSP