#!/bin/bash

# Hyperledger Fabric Voting System Network Setup Script
# This script sets up the complete Fabric network for the voting system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_status "Prerequisites check passed."
}

# Clean up previous network
cleanup_network() {
    print_status "Cleaning up previous network..."
    
    cd network
    
    # Stop and remove containers
    docker-compose down --volumes --remove-orphans
    
    # Remove old certificates and artifacts
    rm -rf organizations/peerOrganizations
    rm -rf organizations/ordererOrganizations
    rm -rf channel-artifacts
    
    cd ..
    
    print_status "Cleanup completed."
}

# Generate certificates and network artifacts
generate_artifacts() {
    print_status "Generating network artifacts..."
    
    cd network
    
    # Create organizations directory structure
    mkdir -p organizations/peerOrganizations
    mkdir -p organizations/ordererOrganizations
    mkdir -p channel-artifacts
    
    # Generate certificates using cryptogen (if available) or use existing ones
    if [ -f "../bin/cryptogen" ]; then
        print_status "Using cryptogen to generate certificates..."
        ../bin/cryptogen generate --config=organizations/cryptogen/crypto-config.yaml --output="organizations"
    else
        print_warning "Cryptogen not found. Using existing certificates or manual setup required."
    fi
    
    # Generate genesis block
    if [ -f "../bin/configtxgen" ]; then
        print_status "Generating genesis block..."
        export FABRIC_CFG_PATH=$PWD
        ../bin/configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
        
        # Generate channel transaction
        print_status "Generating channel transaction..."
        ../bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/votingchannel.tx -channelID votingchannel
        
        # Generate anchor peer transactions
        print_status "Generating anchor peer transactions..."
        ../bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ElectionCommissionMSPanchors.tx -channelID votingchannel -asOrg ElectionCommissionMSP
        ../bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/AuditorMSPanchors.tx -channelID votingchannel -asOrg AuditorMSP
    else
        print_warning "Configtxgen not found. Using existing artifacts or manual setup required."
    fi
    
    cd ..
    
    print_status "Artifacts generation completed."
}

# Start the network
start_network() {
    print_status "Starting Fabric network..."
    
    cd network
    docker-compose up -d
    
    cd ..
    
    print_status "Network started successfully."
}

# Wait for network to be ready
wait_for_network() {
    print_status "Waiting for network to be ready..."
    
    # Wait for orderer
    timeout 60 bash -c 'until docker logs orderer.example.com 2>&1 | grep -q "Starting orderer"; do sleep 2; done'
    
    # Wait for peers
    timeout 60 bash -c 'until docker logs peer0.electioncommission.example.com 2>&1 | grep -q "Started peer"; do sleep 2; done'
    timeout 60 bash -c 'until docker logs peer0.auditor.example.com 2>&1 | grep -q "Started peer"; do sleep 2; done'
    
    print_status "Network is ready."
}

# Create and join channel
setup_channel() {
    print_status "Setting up channel..."
    
    cd network
    
    # Create channel
    docker exec cli peer channel create -o orderer.example.com:7050 -c votingchannel --file ./channel-artifacts/votingchannel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    
    # Join Election Commission peer to channel
    docker exec cli peer channel join -b votingchannel.block
    
    # Switch to Auditor peer
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP -e CORE_PEER_ADDRESS=peer0.auditor.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp cli peer channel join -b votingchannel.block
    
    # Update anchor peers
    docker exec cli peer channel update -o orderer.example.com:7050 -c votingchannel -f ./channel-artifacts/ElectionCommissionMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP -e CORE_PEER_ADDRESS=peer0.auditor.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp cli peer channel update -o orderer.example.com:7050 -c votingchannel -f ./channel-artifacts/AuditorMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    
    cd ..
    
    print_status "Channel setup completed."
}

# Deploy chaincode
deploy_chaincode() {
    print_status "Deploying voting chaincode..."
    
    cd network
    
    # Package chaincode
    docker exec cli peer lifecycle chaincode package votingcc.tar.gz --path /opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/voting --lang golang --label votingcc_1.0
    
    # Install chaincode on Election Commission peer
    docker exec cli peer lifecycle chaincode install votingcc.tar.gz
    
    # Install chaincode on Auditor peer
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP -e CORE_PEER_ADDRESS=peer0.auditor.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp cli peer lifecycle chaincode install votingcc.tar.gz
    
    # Approve chaincode definition
    docker exec cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID votingchannel --name votingcc --version 1.0 --package-id votingcc_1.0 --sequence 1
    
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP -e CORE_PEER_ADDRESS=peer0.auditor.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID votingchannel --name votingcc --version 1.0 --package-id votingcc_1.0 --sequence 1
    
    # Commit chaincode definition
    docker exec cli peer lifecycle chaincode commit -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID votingchannel --name votingcc --version 1.0 --sequence 1
    
    cd ..
    
    print_status "Chaincode deployment completed."
}

# Main execution
main() {
    print_status "Starting Hyperledger Fabric Voting System Network Setup..."
    
    check_prerequisites
    cleanup_network
    generate_artifacts
    start_network
    wait_for_network
    setup_channel
    deploy_chaincode
    
    print_status "Network setup completed successfully!"
    print_status "You can now start the backend API server."
}

# Run main function
main "$@"
