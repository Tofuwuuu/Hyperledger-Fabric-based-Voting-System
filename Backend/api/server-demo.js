const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const bodyParser = require('body-parser');
require('dotenv').config();
const morgan = require('morgan');

const config = require('../config/config');
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
    
    const connectionProfile = require(path.join(__dirname, '..', 'connection-profile.json'));
    
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
app.get('/api/health', async (req, res) => {
    const status = {
        success: true,
        message: 'Voting System Demo API is running',
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

// Demo: Register voter (no auth required)
app.post('/api/voter/register', async (req, res) => {
    try {
        const { voterId } = req.body;
        
        if (!voterId) {
            return res.status(400).json({ 
                success: false, 
                message: 'Voter ID is required' 
            });
        }

        // Try to register voter on blockchain
        try {
            const { gateway, contract } = await connectToNetwork('admin');
            await contract.submitTransaction('RegisterVoter', voterId);
            gateway.disconnect();
            
            res.json({ 
                success: true, 
                message: `Voter ${voterId} registered successfully on blockchain`,
                blockchain: true
            });
        } catch (blockchainError) {
            // If blockchain is not available, simulate the response
            res.json({ 
                success: true, 
                message: `Voter ${voterId} would be registered on blockchain (Demo Mode)`,
                blockchain: false,
                note: 'Blockchain network not fully configured'
            });
        }

    } catch (error) {
        console.error('Voter registration error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Demo: Cast vote (no auth required)
app.post('/api/vote/cast', async (req, res) => {
    try {
        const { voterId, candidateId } = req.body;
        
        if (!voterId || !candidateId) {
            return res.status(400).json({ 
                success: false, 
                message: 'Voter ID and Candidate ID are required' 
            });
        }

        // Try to cast vote on blockchain
        try {
            const { gateway, contract } = await connectToNetwork('admin');
            await contract.submitTransaction('CastVote', voterId, candidateId);
            gateway.disconnect();
            
            res.json({ 
                success: true, 
                message: `Vote cast successfully for candidate ${candidateId}`,
                blockchain: true
            });
        } catch (blockchainError) {
            // If blockchain is not available, simulate the response
            res.json({ 
                success: true, 
                message: `Vote would be cast for candidate ${candidateId} (Demo Mode)`,
                blockchain: false,
                note: 'Blockchain network not fully configured'
            });
        }
        
    } catch (error) {
        console.error('Vote casting error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Demo: Get all candidates
app.get('/api/candidates', async (req, res) => {
    try {
        // Try to get candidates from blockchain
        try {
            const { gateway, contract } = await connectToNetwork('admin');
            const result = await contract.evaluateTransaction('GetAllCandidates');
            const candidates = JSON.parse(result.toString()).map(c => ({
                id: c.candidateID || c.CandidateID,
                name: c.name || c.Name || '',
                party: c.party || c.Party || ''
            }));
            gateway.disconnect();
            
            res.json({ 
                success: true, 
                candidates,
                blockchain: true
            });
        } catch (blockchainError) {
            // If blockchain is not available, return demo candidates
            const demoCandidates = [
                { id: '1', name: 'Alice Johnson', party: 'Democratic Party' },
                { id: '2', name: 'Bob Smith', party: 'Republican Party' },
                { id: '3', name: 'Carol Davis', party: 'Independent' }
            ];
            
            res.json({ 
                success: true, 
                candidates: demoCandidates,
                blockchain: false,
                note: 'Demo candidates - Blockchain network not fully configured'
            });
        }
    } catch (error) {
        console.error('Candidates fetch error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Demo: Get results
app.get('/api/results/:candidateId?', async (req, res) => {
    try {
        const { candidateId } = req.params;
        
        // Try to get results from blockchain
        try {
            const { gateway, contract } = await connectToNetwork('admin');
            let result;
            if (candidateId) {
                result = await contract.evaluateTransaction('QueryResults', candidateId);
            } else {
                result = await contract.evaluateTransaction('GetAllResults');
            }
            gateway.disconnect();
            
            res.json({ 
                success: true, 
                results: JSON.parse(result.toString()),
                blockchain: true
            });
        } catch (blockchainError) {
            // If blockchain is not available, return demo results
            const demoResults = {
                totalVotes: 150,
                candidates: [
                    { id: '1', name: 'Alice Johnson', votes: 75 },
                    { id: '2', name: 'Bob Smith', votes: 60 },
                    { id: '3', name: 'Carol Davis', votes: 15 }
                ]
            };
            
            res.json({ 
                success: true, 
                results: demoResults,
                blockchain: false,
                note: 'Demo results - Blockchain network not fully configured'
            });
        }
    } catch (error) {
        console.error('Results query error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Demo: Seed candidates
app.post('/api/candidates/seed', async (req, res) => {
    try {
        const candidates = req.body?.candidates || [
            { id: '1', name: 'Alice Johnson', party: 'Democratic Party' },
            { id: '2', name: 'Bob Smith', party: 'Republican Party' },
            { id: '3', name: 'Carol Davis', party: 'Independent' }
        ];
        
        // Try to seed candidates on blockchain
        try {
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
            gateway.disconnect();
            
            res.json({ 
                success: true, 
                message: 'Candidates seeded on blockchain',
                blockchain: true
            });
        } catch (blockchainError) {
            res.json({ 
                success: true, 
                message: 'Demo candidates prepared (Blockchain not available)',
                blockchain: false,
                note: 'Blockchain network not fully configured'
            });
        }
    } catch (error) {
        console.error('Seed candidates error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Demo: Get election public key
app.get('/api/election/public-key', async (req, res) => {
    try {
        const publicKey = process.env.ELECTION_PUBLIC_KEY || '-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...\n-----END PUBLIC KEY-----';
        res.json({ success: true, publicKey });
    } catch (error) {
        console.error('Public key fetch error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Demo: Get voter info
app.get('/api/voter/:voterId', async (req, res) => {
    try {
        const { voterId } = req.params;
        
        // Try to get voter info from blockchain
        try {
            const { gateway, contract } = await connectToNetwork('admin');
            const result = await contract.evaluateTransaction('GetVoter', voterId);
            const voter = JSON.parse(result.toString());
            gateway.disconnect();
            
            res.json({ 
                success: true, 
                voter: {
                    voterId: voter.voterID || voter.VoterID,
                    hasVoted: voter.hasVoted || voter.HasVoted,
                    votedFor: voter.votedFor || voter.VotedFor
                },
                blockchain: true
            });
        } catch (blockchainError) {
            // If blockchain is not available, return demo voter info
            res.json({ 
                success: true, 
                voter: {
                    voterId: voterId,
                    hasVoted: false,
                    votedFor: null
                },
                blockchain: false,
                note: 'Demo voter info - Blockchain network not fully configured'
            });
        }
    } catch (error) {
        console.error('Voter info fetch error:', error);
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
    console.log(`Voting System Demo API running on port ${port}`);
    console.log(`Environment: ${config.server.nodeEnv}`);
    console.log('🔓 Demo Mode: No authentication required');
    console.log('📊 Blockchain features will work if network is configured');
});
