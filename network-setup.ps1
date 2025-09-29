# Hyperledger Fabric Voting System Network Setup Script (PowerShell)
# This script sets up the complete Fabric network for the voting system

param(
    [switch]$Cleanup,
    [switch]$StartOnly,
    [switch]$StopOnly
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if required tools are installed
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed. Please install Docker Desktop first."
        exit 1
    }
    
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Write-Error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    }
    
    Write-Status "Prerequisites check passed."
}

# Clean up previous network
function Stop-Network {
    Write-Status "Cleaning up previous network..."
    
    Set-Location network
    
    # Stop and remove containers
    docker-compose down --volumes --remove-orphans
    
    # Remove old certificates and artifacts (optional)
    if (Test-Path "organizations/peerOrganizations") {
        Remove-Item -Recurse -Force "organizations/peerOrganizations"
    }
    if (Test-Path "organizations/ordererOrganizations") {
        Remove-Item -Recurse -Force "organizations/ordererOrganizations"
    }
    if (Test-Path "channel-artifacts") {
        Remove-Item -Recurse -Force "channel-artifacts"
    }
    
    Set-Location ..
    
    Write-Status "Cleanup completed."
}

# Generate certificates and network artifacts
function New-NetworkArtifacts {
    Write-Status "Generating network artifacts..."
    
    Set-Location network
    
    # Create organizations directory structure
    New-Item -ItemType Directory -Force -Path "organizations/peerOrganizations" | Out-Null
    New-Item -ItemType Directory -Force -Path "organizations/ordererOrganizations" | Out-Null
    New-Item -ItemType Directory -Force -Path "channel-artifacts" | Out-Null
    
    # Copy existing certificates if they exist
    if (Test-Path "../organizations/peerOrganizations") {
        Copy-Item -Recurse -Force "../organizations/peerOrganizations/*" "organizations/peerOrganizations/"
        Write-Status "Copied existing peer organization certificates."
    }
    
    if (Test-Path "../organizations/ordererOrganizations") {
        Copy-Item -Recurse -Force "../organizations/ordererOrganizations/*" "organizations/ordererOrganizations/"
        Write-Status "Copied existing orderer organization certificates."
    }
    
    # Copy existing channel artifacts if they exist
    if (Test-Path "../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/genesis.block") {
        Copy-Item "../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/genesis.block" "channel-artifacts/"
        Write-Status "Copied existing genesis block."
    }
    
    if (Test-Path "../organizations/peerOrganizations/electioncommission.example.com/msp/votingchannel.tx") {
        Copy-Item "../organizations/peerOrganizations/electioncommission.example.com/msp/votingchannel.tx" "channel-artifacts/"
        Write-Status "Copied existing channel transaction."
    }
    
    Set-Location ..
    
    Write-Status "Artifacts preparation completed."
}

# Start the network
function Start-Network {
    Write-Status "Starting Fabric network..."
    
    Set-Location network
    docker-compose up -d
    Set-Location ..
    
    Write-Status "Network started successfully."
}

# Wait for network to be ready
function Wait-ForNetwork {
    Write-Status "Waiting for network to be ready..."
    
    # Wait for orderer
    $timeout = 60
    $elapsed = 0
    do {
        Start-Sleep -Seconds 2
        $elapsed += 2
        $ordererLogs = docker logs orderer.example.com 2>&1 | Select-String "Starting orderer"
    } while (-not $ordererLogs -and $elapsed -lt $timeout)
    
    if ($elapsed -ge $timeout) {
        Write-Warning "Timeout waiting for orderer to start."
    }
    
    # Wait for peers
    $elapsed = 0
    do {
        Start-Sleep -Seconds 2
        $elapsed += 2
        $peer1Logs = docker logs peer0.electioncommission.example.com 2>&1 | Select-String "Started peer"
        $peer2Logs = docker logs peer0.auditor.example.com 2>&1 | Select-String "Started peer"
    } while ((-not $peer1Logs -or -not $peer2Logs) -and $elapsed -lt $timeout)
    
    if ($elapsed -ge $timeout) {
        Write-Warning "Timeout waiting for peers to start."
    }
    
    Write-Status "Network is ready."
}

# Create and join channel
function New-Channel {
    Write-Status "Setting up channel..."
    
    Set-Location network
    
    # Create channel
    docker exec cli peer channel create -o orderer.example.com:7050 -c votingchannel --file ./channel-artifacts/votingchannel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    
    # Join Election Commission peer to channel
    docker exec cli peer channel join -b votingchannel.block
    
    # Switch to Auditor peer
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP -e CORE_PEER_ADDRESS=peer0.auditor.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp cli peer channel join -b votingchannel.block
    
    Set-Location ..
    
    Write-Status "Channel setup completed."
}

# Deploy chaincode
function Deploy-Chaincode {
    Write-Status "Deploying voting chaincode..."
    
    Set-Location network
    
    # Copy chaincode to network directory
    if (Test-Path "../chaincode/voting") {
        New-Item -ItemType Directory -Force -Path "chaincode" | Out-Null
        Copy-Item -Recurse -Force "../chaincode/voting" "chaincode/"
    }
    
    # Package chaincode
    docker exec cli peer lifecycle chaincode package votingcc.tar.gz --path /opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/voting --lang golang --label votingcc_1.0
    
    # Install chaincode on both peers
    docker exec cli peer lifecycle chaincode install votingcc.tar.gz
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP -e CORE_PEER_ADDRESS=peer0.auditor.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp cli peer lifecycle chaincode install votingcc.tar.gz
    
    # Approve and commit chaincode
    docker exec cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID votingchannel --name votingcc --version 1.0 --package-id votingcc_1.0 --sequence 1
    
    docker exec -e CORE_PEER_LOCALMSPID=AuditorMSP -e CORE_PEER_ADDRESS=peer0.auditor.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID votingchannel --name votingcc --version 1.0 --package-id votingcc_1.0 --sequence 1
    
    docker exec cli peer lifecycle chaincode commit -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID votingchannel --name votingcc --version 1.0 --sequence 1
    
    Set-Location ..
    
    Write-Status "Chaincode deployment completed."
}

# Main execution
function Main {
    Write-Status "Starting Hyperledger Fabric Voting System Network Setup..."
    
    if ($StopOnly) {
        Stop-Network
        return
    }
    
    if ($StartOnly) {
        Start-Network
        Wait-ForNetwork
        return
    }
    
    if ($Cleanup) {
        Stop-Network
        return
    }
    
    Test-Prerequisites
    Stop-Network
    New-NetworkArtifacts
    Start-Network
    Wait-ForNetwork
    New-Channel
    Deploy-Chaincode
    
    Write-Status "Network setup completed successfully!"
    Write-Status "You can now start the backend API server."
}

# Run main function
Main
