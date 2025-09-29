# Hyperledger Fabric-based Voting System

A secure, transparent, and tamper-proof electronic voting system built on Hyperledger Fabric blockchain technology.

## Overview

This voting system provides:
- **Secure Voting**: Blockchain-based vote storage ensures immutability
- **Transparency**: All transactions are recorded on the blockchain
- **Privacy**: Vote encryption ensures voter anonymity
- **Auditability**: Complete audit trail for verification
- **Role-based Access**: Admin, Voter, and Auditor roles with appropriate permissions

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │  Fabric Network │
│   (React)       │◄──►│   (Node.js)     │◄──►│   (Blockchain)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Components

- **Frontend**: React-based web application with Material-UI
- **Backend**: Node.js API server with JWT authentication
- **Blockchain**: Hyperledger Fabric network with voting chaincode
- **Database**: Blockchain ledger (no traditional database needed)

## Prerequisites

- **Node.js** (v14 or higher)
- **Docker** and **Docker Compose**
- **Git**

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Hyperledger-Fabric-based-Voting-System
```

### 2. Setup the Blockchain Network

#### On Windows (PowerShell):
```powershell
.\network-setup.ps1
```

#### On Linux/Mac (Bash):
```bash
chmod +x network-setup.sh
./network-setup.sh
```

### 3. Start the Backend API

```bash
cd Backend
npm install
npm start
```

The API will be available at `http://localhost:3001`

### 4. Start the Frontend

```bash
cd Frontend
npm install
npm start
```

The frontend will be available at `http://localhost:3000`

## Network Configuration

The system uses a 3-organization Fabric network:

- **ElectionCommission**: Manages the election process
- **Auditor**: Provides oversight and auditing capabilities
- **Orderer**: Consensus service

### Network Topology

```
Orderer (example.com:7050)
├── ElectionCommission Peer (electioncommission.example.com:7051)
└── Auditor Peer (auditor.example.com:9051)
```

## API Documentation

### Authentication

All API endpoints (except health check and login) require JWT authentication:

```bash
curl -H "Authorization: Bearer <token>" http://localhost:3001/api/endpoint
```

### Key Endpoints

- `POST /api/login` - User authentication
- `POST /api/voter/register` - Register voter (Admin only)
- `POST /api/vote/cast` - Cast vote (Voter only)
- `GET /api/results/:candidateId` - Get results (Admin/Auditor only)
- `GET /api/candidates` - Get candidate list
- `GET /api/health` - Health check

## User Roles

### Admin
- Register voters
- View election results
- Manage election process

### Voter
- Cast votes
- View own voting status

### Auditor
- View election results
- Audit voting process
- Verify election integrity

## Security Features

- **Blockchain Immutability**: Votes cannot be modified once recorded
- **Encryption**: Votes are encrypted before transmission
- **Authentication**: JWT-based authentication
- **Authorization**: Role-based access control
- **Rate Limiting**: Protection against abuse
- **Audit Trail**: Complete transaction history

## Development

### Project Structure

```
├── Backend/                 # Node.js API server
│   ├── api/                # API endpoints
│   ├── middleware/         # Authentication middleware
│   ├── services/          # Fabric services
│   └── config/            # Configuration
├── Frontend/              # React application
│   ├── src/
│   │   ├── components/    # React components
│   │   └── utils/         # Utility functions
├── chaincode/             # Fabric chaincode
│   └── voting/           # Voting smart contract
├── network/              # Fabric network configuration
│   ├── docker-compose.yaml
│   ├── configtx.yaml
│   └── organizations/
└── organizations/        # Certificates and MSPs
```

### Adding New Features

1. **Backend**: Add endpoints in `Backend/api/server.js`
2. **Frontend**: Create components in `Frontend/src/components/`
3. **Chaincode**: Modify `chaincode/voting/voting.go`
4. **Network**: Update configuration files as needed

## Testing

### Manual Testing

1. Start the network and applications
2. Login as admin and register voters
3. Login as voter and cast votes
4. Verify results as auditor

### API Testing

Use tools like Postman or curl to test endpoints:

```bash
# Login
curl -X POST http://localhost:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"userId":"admin","password":"password","role":"admin"}'

# Register voter
curl -X POST http://localhost:3001/api/voter/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"voterId":"voter123"}'
```

## Troubleshooting

### Common Issues

1. **Network won't start**
   - Check Docker is running
   - Verify port availability (7050, 7051, 9051)
   - Check certificate generation

2. **API connection fails**
   - Verify Fabric network is running
   - Check connection profile configuration
   - Ensure wallet contains identities

3. **Frontend errors**
   - Check backend API is running
   - Verify CORS configuration
   - Check browser console for errors

### Logs

- **Backend**: Check console output
- **Network**: Use `docker logs <container-name>`
- **Frontend**: Check browser developer tools

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review existing issues
3. Create a new issue with detailed information

## Future Enhancements

- [ ] Multi-election support
- [ ] Advanced encryption schemes
- [ ] Mobile application
- [ ] Real-time result updates
- [ ] Integration with external identity providers
- [ ] Advanced audit features