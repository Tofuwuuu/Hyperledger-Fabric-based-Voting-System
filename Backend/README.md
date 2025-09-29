# Voting System Backend API

This is the backend API for the Hyperledger Fabric-based Voting System. It provides RESTful endpoints for voter registration, voting, and result querying.

## Features

- **JWT Authentication**: Secure token-based authentication
- **Role-based Access Control**: Admin, Voter, and Auditor roles
- **Hyperledger Fabric Integration**: Direct blockchain integration for voting operations
- **Rate Limiting**: Protection against abuse
- **Security Headers**: Helmet.js for security headers
- **Error Handling**: Comprehensive error handling and logging

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Docker and Docker Compose
- Hyperledger Fabric network running

## Installation

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file in the Backend directory:
```env
PORT=3001
NODE_ENV=development
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=24h
CHANNEL_NAME=votingchannel
CHAINCODE_NAME=votingcc
MSP_ID=ElectionCommissionMSP
WALLET_PATH=./wallet
```

3. Ensure the Fabric network is running (see main project README)

4. Start the server:
```bash
npm start
# or for development
npm run dev
```

## API Endpoints

### Authentication

#### POST /api/login
Login to the system.

**Request Body:**
```json
{
  "userId": "admin",
  "password": "password",
  "role": "admin"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "jwt-token-here",
  "user": {
    "userId": "admin",
    "role": "admin"
  }
}
```

### Voter Management

#### POST /api/voter/register
Register a new voter (Admin only).

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "voterId": "voter123"
}
```

### Voting

#### POST /api/vote/cast
Cast a vote (Voter only).

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "candidateId": "candidate1"
}
```

### Results

#### GET /api/results/:candidateId
Get vote results for a specific candidate (Admin/Auditor only).

**Headers:**
```
Authorization: Bearer <token>
```

### System

#### GET /api/health
Health check endpoint.

**Response:**
```json
{
  "success": true,
  "message": "Voting System API is running",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

#### GET /api/candidates
Get list of candidates.

**Headers:**
```
Authorization: Bearer <token>
```

#### GET /api/election/public-key
Get election public key for vote encryption.

**Headers:**
```
Authorization: Bearer <token>
```

## Authentication

The API uses JWT tokens for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

### Roles

- **admin**: Can register voters and view results
- **voter**: Can cast votes
- **auditor**: Can view results for auditing purposes

## Configuration

The API configuration is managed through the `config/config.js` file and environment variables:

- `PORT`: Server port (default: 3001)
- `JWT_SECRET`: Secret key for JWT signing
- `JWT_EXPIRES_IN`: Token expiration time
- `CHANNEL_NAME`: Fabric channel name
- `CHAINCODE_NAME`: Fabric chaincode name
- `MSP_ID`: Member Service Provider ID
- `WALLET_PATH`: Path to Fabric wallet

## Security Features

- **Helmet.js**: Security headers
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **JWT Authentication**: Secure token-based auth
- **Role-based Authorization**: Granular access control
- **Input Validation**: Request body validation
- **Error Handling**: Secure error responses

## Development

### Project Structure

```
Backend/
├── api/
│   └── server.js          # Main server file
├── middleware/
│   └── auth.js            # Authentication middleware
├── services/
│   └── fabric-ca-service.js # Fabric CA service
├── config/
│   └── config.js          # Configuration
├── connection-profile.json # Fabric connection profile
└── package.json
```

### Adding New Endpoints

1. Add the endpoint in `api/server.js`
2. Apply appropriate authentication middleware
3. Add input validation
4. Implement error handling
5. Update this README

### Testing

Test the API endpoints using tools like Postman or curl:

```bash
# Health check
curl http://localhost:3001/api/health

# Login
curl -X POST http://localhost:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"userId":"admin","password":"password","role":"admin"}'
```

## Troubleshooting

### Common Issues

1. **Connection to Fabric network fails**
   - Ensure Fabric network is running
   - Check connection profile configuration
   - Verify wallet contains required identities

2. **Authentication fails**
   - Check JWT secret configuration
   - Verify token is included in Authorization header
   - Ensure user has required role

3. **Rate limiting errors**
   - Wait for rate limit window to reset
   - Consider increasing rate limits for development

### Logs

Check the console output for detailed error messages and logs.

## Contributing

1. Follow the existing code style
2. Add proper error handling
3. Include input validation
4. Update documentation
5. Test thoroughly
