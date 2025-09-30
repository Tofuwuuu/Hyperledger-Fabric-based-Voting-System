const jwt = require('jsonwebtoken');
const { Wallets } = require('fabric-network');
const path = require('path');
const config = require('../config/config');

const authenticate = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        if (!token) {
            return res.status(401).json({ success: false, message: 'Authentication token required' });
        }

        const decoded = jwt.verify(token, config.jwt.secret);
        
        // Get wallet
        const walletPath = path.isAbsolute(config.fabric.walletPath)
            ? config.fabric.walletPath
            : path.join(process.cwd(), config.fabric.walletPath);
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        
        // Check if user exists in wallet
        const identity = await wallet.get(decoded.userId);
        if (!identity) {
            return res.status(401).json({ success: false, message: 'Invalid user credentials' });
        }

        // Add user info to request
        req.user = {
            userId: decoded.userId,
            role: decoded.role
        };

        next();
    } catch (error) {
        console.error(`Authentication error: ${error}`);
        return res.status(401).json({ success: false, message: 'Invalid authentication token' });
    }
};

const authorizeAdmin = (req, res, next) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Access denied. Admin rights required.' });
    }
    next();
};

const authorizeVoter = (req, res, next) => {
    if (req.user.role !== 'voter') {
        return res.status(403).json({ success: false, message: 'Access denied. Voter rights required.' });
    }
    next();
};

const authorizeAuditor = (req, res, next) => {
    if (req.user.role !== 'auditor') {
        return res.status(403).json({ success: false, message: 'Access denied. Auditor rights required.' });
    }
    next();
};

module.exports = {
    authenticate,
    authorizeAdmin,
    authorizeVoter,
    authorizeAuditor
};