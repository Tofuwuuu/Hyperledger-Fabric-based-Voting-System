module.exports = {
    server: {
        port: process.env.PORT || 3001,
        nodeEnv: process.env.NODE_ENV || 'development'
    },
    jwt: {
        secret: process.env.JWT_SECRET || 'voting-system-secret-key-2024',
        expiresIn: process.env.JWT_EXPIRES_IN || '24h'
    },
    fabric: {
        channelName: process.env.CHANNEL_NAME || 'votingchannel',
        chaincodeName: process.env.CHAINCODE_NAME || 'votingcc',
        mspId: process.env.MSP_ID || 'ElectionCommissionMSP',
        walletPath: process.env.WALLET_PATH || './wallet'
    },
    rateLimit: {
        windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
        max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
    }
};
