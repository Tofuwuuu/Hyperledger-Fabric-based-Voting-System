#!/bin/bash

# Download Fabric binaries and docker images
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.0 1.5.5

# Move binaries to bin directory
mkdir -p bin
cp fabric-samples/bin/* bin/
rm -rf fabric-samples

# Create necessary directories
mkdir -p network/channel-artifacts
mkdir -p network/organizations/ordererOrganizations
mkdir -p network/organizations/peerOrganizations
mkdir -p network/organizations/fabric-ca

# Set up environment variables
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/config