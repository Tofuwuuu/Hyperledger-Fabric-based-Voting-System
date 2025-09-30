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
const morgan = require('morgan');

const { authenticate, authorizeAdmin, authorizeVoter, authorizeAuditor } = require('../middleware/auth');
const config = require('../config/config');
const FabricCAService = require('../services/fabric-ca-service');
const fs = require('fs');

const app = express();
const port = config.server.port;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));

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

// Bootstrap: Ensure CA admin exists in wallet on startup
async function bootstrapAdminIdentity() {
    try {
        const caService = new FabricCAService(config.fabric.caName, config.fabric.walletPath, config.fabric.mspId);
        await caService.init();
        await caService.enrollAdmin();
    } catch (err) {
        console.error('Admin enrollment failed:', err.message || err);
    }
}

bootstrapAdminIdentity();

// Health check endpoint (extended Fabric readiness)
app.get('/api/health', async (req, res) => {
    const status = {
        success: true,
        message: 'Voting System API is running',
        timestamp: new Date().toISOString(),
        fabric: { connected: false, walletHasAdmin: false, channel: config.fabric.channelName, chaincode: config.fabric.chaincodeName }
    };
    try {
        const wallet = await Wallets.newFileSystemWallet(config.fabric.walletPath);
        const admin = await wallet.get('admin');
        status.fabric.walletHasAdmin = !!admin;
        const { gateway, contract } = await connectToNetwork('admin');
        await contract.evaluateTransaction('GetAllCandidates');
        status.fabric.connected = true;
        gateway.disconnect();
    } catch (e) {
        status.success = false;
        status.fabric.error = e?.message || String(e);
    }
    res.status(status.success ? 200 : 503).json(status);
});

// Demo users store (replace with DB in production)
const demoUsers = [
    { userId: 'admin', role: 'admin', passwordHash: bcrypt.hashSync('password', 10) },
    { userId: 'voter1', role: 'voter', passwordHash: bcrypt.hashSync('password', 10) },
    { userId: 'auditor1', role: 'auditor', passwordHash: bcrypt.hashSync('password', 10) }
];

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

        const user = demoUsers.find(u => u.userId === userId && u.role === role);
        if (!user) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }
        const ok = await bcrypt.compare(password, user.passwordHash);
        if (!ok) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
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

        // Register and enroll voter with CA first
        const caService = new FabricCAService(config.fabric.caName, config.fabric.walletPath, config.fabric.mspId);
        await caService.init();
        await caService.registerAndEnrollUser(voterId, 'client');

        // Then register voter on-chain using admin identity
        const { gateway, contract } = await connectToNetwork('admin');
        await contract.submitTransaction('RegisterVoter', voterId);

        res.json({ success: true, message: 'Voter registered and enrolled successfully' });

        gateway.disconnect();
    } catch (error) {
        console.error('Voter registration error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Cast vote endpoint (Voter only)
app.post('/api/vote/cast', authenticate, authorizeVoter, async (req, res) => {
    try {
        const { candidateId, encryptedVote, ballotHash } = req.body;
        const voterId = req.user.userId;
        
        if (!candidateId) {
            return res.status(400).json({ 
                success: false, 
                message: 'Candidate ID is required' 
            });
        }

        const { gateway, contract } = await connectToNetwork(voterId);

        await contract.submitTransaction('CastVote', voterId, candidateId);
        if (ballotHash) {
            try {
                await contract.submitTransaction('SubmitBallotHash', voterId, ballotHash);
            } catch (e) {
                console.warn('Failed to submit ballot hash:', e?.message || e);
            }
        }
        
        res.json({ success: true, message: 'Vote cast successfully' });
        
        gateway.disconnect();
    } catch (error) {
        console.error('Vote casting error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Verify endpoint: returns recorded ballot hash for the voter
app.get('/api/vote/verify', authenticate, authorizeVoter, async (req, res) => {
    try {
        const voterId = req.user.userId;
        const { gateway, contract } = await connectToNetwork('admin');
        const result = await contract.evaluateTransaction('GetVoter', voterId);
        const voter = JSON.parse(result.toString());
        res.json({ success: true, voter: { voterId: voter.voterID || voter.VoterID, ballotHash: voter.ballotHash || voter.BallotHash, hasVoted: voter.hasVoted || voter.HasVoted, votedFor: voter.votedFor || voter.VotedFor } });
        gateway.disconnect();
    } catch (error) {
        console.error('Verify fetch error:', error);
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
        const { gateway, contract } = await connectToNetwork('admin');
        const result = await contract.evaluateTransaction('GetAllCandidates');
        const candidates = JSON.parse(result.toString()).map(c => ({
            id: c.candidateID || c.CandidateID,
            name: c.name || c.Name || '',
            party: c.party || c.Party || ''
        }));
        res.json({ success: true, candidates });
        gateway.disconnect();
    } catch (error) {
        console.error('Candidates fetch error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Admin-only: seed candidates from config
app.post('/api/candidates/seed', authenticate, authorizeAdmin, async (req, res) => {
    try {
        const candidates = req.body?.candidates || [];
        if (!Array.isArray(candidates) || candidates.length === 0) {
            return res.status(400).json({ success: false, message: 'candidates array required' });
        }
        const { gateway, contract } = await connectToNetwork('admin');
        for (const c of candidates) {
            const id = c.id || c.candidateID;
            const name = c.name || '';
            const party = c.party || '';
            if (!id) continue;
            try {
                await contract.submitTransaction('CreateCandidate', String(id), String(name), String(party));
            } catch (e) {
                // Ignore already exists errors
                if (!String(e?.message || '').includes('already exists')) {
                    throw e;
                }
            }
        }
        res.json({ success: true, message: 'Candidates seeded' });
        gateway.disconnect();
    } catch (error) {
        console.error('Seed candidates error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Get election public key endpoint (public)
app.get('/api/election/public-key', async (req, res) => {
    try {
        // In production, load from secure storage or env
        const publicKey = process.env.ELECTION_PUBLIC_KEY || '-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...\n-----END PUBLIC KEY-----';
        
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