const express = require('express');
const cors = require('cors');
const { Gateway, Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const path = require('path');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3001;

app.use(cors());
app.use(bodyParser.json());

// Fabric network configuration
const channelName = 'votingchannel';
const chaincodeName = 'votingcc';
const mspOrg1 = 'ElectionCommissionMSP';
const walletPath = path.join(__dirname, 'wallet');

// API endpoints
app.post('/api/register', async (req, res) => {
    try {
        const { voterId } = req.body;
        
        // Connect to network
        const gateway = new Gateway();
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        
        // Get connection profile
        const connectionProfile = require('./connection-profile.json');
        
        await gateway.connect(connectionProfile, {
            wallet,
            identity: 'admin',
            discovery: { enabled: true, asLocalhost: true }
        });

        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(chaincodeName);

        // Submit transaction
        await contract.submitTransaction('RegisterVoter', voterId);
        
        res.json({ success: true, message: 'Voter registered successfully' });
        
        gateway.disconnect();
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

app.post('/api/vote', async (req, res) => {
    try {
        const { voterId, candidateId } = req.body;
        
        const gateway = new Gateway();
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        const connectionProfile = require('./connection-profile.json');
        
        await gateway.connect(connectionProfile, {
            wallet,
            identity: voterId,
            discovery: { enabled: true, asLocalhost: true }
        });

        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(chaincodeName);

        await contract.submitTransaction('CastVote', voterId, candidateId);
        
        res.json({ success: true, message: 'Vote cast successfully' });
        
        gateway.disconnect();
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

app.get('/api/results/:candidateId', async (req, res) => {
    try {
        const { candidateId } = req.params;
        
        const gateway = new Gateway();
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        const connectionProfile = require('./connection-profile.json');
        
        await gateway.connect(connectionProfile, {
            wallet,
            identity: 'admin',
            discovery: { enabled: true, asLocalhost: true }
        });

        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(chaincodeName);

        const result = await contract.evaluateTransaction('QueryResults', candidateId);
        
        res.json({ success: true, results: JSON.parse(result.toString()) });
        
        gateway.disconnect();
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});