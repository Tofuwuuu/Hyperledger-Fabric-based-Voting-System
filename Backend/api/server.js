const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Gateway, Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const path = require('path');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const { authenticate, authorizeAdmin, authorizeVoter, authorizeAuditor } = require('../middleware/auth');
const config = require('../config/config');

const app = express();
const port = config.server.port;

// Security middleware
app.use(helmet());
app.use(cors());

// Rate limiting
const limiter = rateLimit({
    windowMs: config.rateLimit.windowMs,
    max: config.rateLimit.max,
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true }));

// Helper function to connect to Fabric network
async function connectToNetwork(identity = 'admin') {
    const gateway = new Gateway();
    const wallet = await Wallets.newFileSystemWallet(config.fabric.walletPath);
    
    const connectionProfile = require('../connection-profile.json');
    
    await gateway.connect(connectionProfile, {
        wallet,
        identity,
        discovery: { enabled: true, asLocalhost: true }
    });

    const network = await gateway.getNetwork(config.fabric.channelName);
    const contract = network.getContract(config.fabric.chaincodeName);
    
    return { gateway, contract };
}

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        success: true, 
        message: 'Voting System API is running',
        timestamp: new Date().toISOString()
    });
});

// Login endpoint
app.post('/api/login', async (req, res) => {
    try {
        const { userId, password, role } = req.body;
        
        if (!userId || !password || !role) {
            return res.status(400).json({ 
                success: false, 
                message: 'User ID, password, and role are required' 
            });
        }

        // In a real system, you would verify credentials against a database
        // For now, we'll use a simple validation
        const validRoles = ['admin', 'voter', 'auditor'];
        if (!validRoles.includes(role)) {
            return res.status(400).json({ 
                success: false, 
                message: 'Invalid role' 
            });
        }

        // Generate JWT token
        const token = jwt.sign(
            { userId, role },
            config.jwt.secret,
            { expiresIn: config.jwt.expiresIn }
        );

        res.json({
            success: true,
            message: 'Login successful',
            token,
            user: { userId, role }
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// Register voter endpoint (Admin only)
app.post('/api/voter/register', authenticate, authorizeAdmin, async (req, res) => {
    try {
        const { voterId } = req.body;
        
        if (!voterId) {
            return res.status(400).json({ 
                success: false, 
                message: 'Voter ID is required' 
            });
        }

        const { gateway, contract } = await connectToNetwork();
        
        // Submit transaction
        await contract.submitTransaction('RegisterVoter', voterId);
        
        res.json({ success: true, message: 'Voter registered successfully' });
        
        gateway.disconnect();
    } catch (error) {
        console.error('Voter registration error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Cast vote endpoint (Voter only)
app.post('/api/vote/cast', authenticate, authorizeVoter, async (req, res) => {
    try {
        const { candidateId } = req.body;
        const voterId = req.user.userId;
        
        if (!candidateId) {
            return res.status(400).json({ 
                success: false, 
                message: 'Candidate ID is required' 
            });
        }

        const { gateway, contract } = await connectToNetwork(voterId);

        await contract.submitTransaction('CastVote', voterId, candidateId);
        
        res.json({ success: true, message: 'Vote cast successfully' });
        
        gateway.disconnect();
    } catch (error) {
        console.error('Vote casting error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Get results endpoint (Admin and Auditor only)
app.get('/api/results/:candidateId', authenticate, (req, res, next) => {
    if (req.user.role === 'admin' || req.user.role === 'auditor') {
        next();
    } else {
        res.status(403).json({ success: false, message: 'Access denied' });
    }
}, async (req, res) => {
    try {
        const { candidateId } = req.params;
        
        const { gateway, contract } = await connectToNetwork();

        const result = await contract.evaluateTransaction('QueryResults', candidateId);
        
        res.json({ success: true, results: JSON.parse(result.toString()) });
        
        gateway.disconnect();
    } catch (error) {
        console.error('Results query error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Get all candidates endpoint
app.get('/api/candidates', authenticate, async (req, res) => {
    try {
        // Mock candidates data - in a real system, this would come from the blockchain
        const candidates = [
            { id: 'candidate1', name: 'John Doe', party: 'Democratic Party' },
            { id: 'candidate2', name: 'Jane Smith', party: 'Republican Party' },
            { id: 'candidate3', name: 'Bob Johnson', party: 'Independent' }
        ];
        
        res.json({ success: true, candidates });
    } catch (error) {
        console.error('Candidates fetch error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Get election public key endpoint (public)
app.get('/api/election/public-key', async (req, res) => {
    try {
        // Mock public key - in a real system, this would be generated securely
        const publicKey = '-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...\n-----END PUBLIC KEY-----';
        
        res.json({ success: true, publicKey });
    } catch (error) {
        console.error('Public key fetch error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        success: false, 
        message: 'Something went wrong!' 
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ 
        success: false, 
        message: 'Endpoint not found' 
    });
});

app.listen(port, () => {
    console.log(`Voting System API running on port ${port}`);
    console.log(`Environment: ${config.server.nodeEnv}`);
});