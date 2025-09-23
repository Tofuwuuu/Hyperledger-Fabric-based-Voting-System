# Hyperledger Fabric-based Voting System

A secure and transparent electronic voting system built using Hyperledger Fabric blockchain technology.

## Architecture Overview

- **Type**: Permissioned blockchain network
- **Framework**: Hyperledger Fabric
- **Consensus**: Raft (production) / Solo (development)
- **Smart Contracts**: Go-based chaincode
- **State Database**: CouchDB (for rich queries)

## Components

1. **Network**
   - Two organizations: Election Commission and Auditors
   - Orderer service using Raft consensus
   - Multiple peers for validation and endorsement

2. **Chaincode**
   - Voter registration
   - Vote casting
   - Result querying
   - Double-voting prevention

3. **Backend API**
   - Node.js Express server
   - Fabric SDK integration
   - RESTful endpoints for voting operations

4. **Frontend**
   - React-based user interface
   - Material-UI components
   - Secure authentication
   - Real-time results viewing

## Prerequisites

- Hyperledger Fabric v2.x
- Docker and Docker Compose
- Node.js v14+
- Go v1.15+
- Python v3.7+ (for scripts)

## Setup Instructions

### 1. Network Setup

```bash
cd network
./network.sh up -ca -s couchdb
./network.sh createChannel -c votingchannel
```

### 2. Deploy Chaincode

```bash
cd chaincode/voting
go mod vendor
cd ../../network
./network.sh deployCC -c votingchannel -ccn votingcc -ccp ../chaincode/voting -ccl go
```

### 3. Backend Setup

```bash
cd Backend
npm install
cp .env.example .env  # Configure your environment variables
npm start
```

### 4. Frontend Setup

```bash
cd Frontend
npm install
npm start
```

## Security Features

- MSP-based identity management
- TLS communication
- Encrypted ballots
- Role-based access control
- Immutable audit trail

## API Endpoints

- POST /api/register - Register a new voter
- POST /api/vote - Cast a vote
- GET /api/results/:candidateId - Query results

## Development Guidelines

1. Follow Hyperledger Fabric best practices
2. Use proper error handling
3. Implement comprehensive logging
4. Maintain test coverage
5. Document API changes

## Production Deployment

1. Configure proper TLS certificates
2. Set up multiple orderers for HA
3. Implement proper backup strategy
4. Monitor network health
5. Set up proper firewalls

## License

This project is licensed under the MIT License - see the LICENSE file for details.