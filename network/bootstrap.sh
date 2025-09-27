#!/bin/bash

# Download Fabric binaries and docker images
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/bootstrap.sh | bash -s -- 2.5.0 1.5.5

# Add binaries to PATH
export PATH=$PWD/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config