const { Wallets, Gateway } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const path = require('path');
const fs = require('fs');

class FabricCAService {
    constructor(caInfo, walletPath, mspId) {
        this.caInfo = caInfo;
        this.walletPath = walletPath;
        this.mspId = mspId;
        this.caClient = null;
        this.wallet = null;
    }

    async init() {
        const ccp = JSON.parse(fs.readFileSync(path.join(process.cwd(), 'Backend', 'connection-profile.json'), 'utf8'));
        const caInfo = ccp.certificateAuthorities[this.caInfo];
        const caTLSCACerts = caInfo.tlsCACerts.pem;
        this.caClient = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);
        this.wallet = await Wallets.newFileSystemWallet(this.walletPath);
    }

    async enrollAdmin() {
        try {
            const identity = await this.wallet.get('admin');
            if (identity) {
                console.log('Admin already exists in the wallet');
                return;
            }

            const enrollment = await this.caClient.enroll({ 
                enrollmentID: 'admin', 
                enrollmentSecret: 'adminpw' 
            });

            const x509Identity = {
                credentials: {
                    certificate: enrollment.certificate,
                    privateKey: enrollment.key.toBytes(),
                },
                mspId: this.mspId,
                type: 'X.509',
            };

            await this.wallet.put('admin', x509Identity);
            console.log('Successfully enrolled admin user and imported it into the wallet');
        } catch (error) {
            console.error(`Failed to enroll admin user: ${error}`);
            throw error;
        }
    }

    async registerAndEnrollUser(userId, role) {
        try {
            const userIdentity = await this.wallet.get(userId);
            if (userIdentity) {
                throw new Error(`User ${userId} already exists in the wallet`);
            }

            const adminIdentity = await this.wallet.get('admin');
            if (!adminIdentity) {
                throw new Error('Admin must be enrolled before registering a new user');
            }

            const provider = this.wallet.getProviderRegistry().getProvider(adminIdentity.type);
            const adminUser = await provider.getUserContext(adminIdentity, 'admin');

            const secret = await this.caClient.register({
                affiliation: 'org1.department1',
                enrollmentID: userId,
                role: role,
                attrs: [{
                    name: 'role',
                    value: role,
                    ecert: true
                }]
            }, adminUser);

            const enrollment = await this.caClient.enroll({
                enrollmentID: userId,
                enrollmentSecret: secret
            });

            const x509Identity = {
                credentials: {
                    certificate: enrollment.certificate,
                    privateKey: enrollment.key.toBytes(),
                },
                mspId: this.mspId,
                type: 'X.509',
            };

            await this.wallet.put(userId, x509Identity);
            console.log(`Successfully registered and enrolled user ${userId} and imported it into the wallet`);
            
            return {
                userId,
                success: true
            };
        } catch (error) {
            console.error(`Failed to register user ${userId}: ${error}`);
            throw error;
        }
    }

    async getUserIdentity(userId) {
        try {
            const identity = await this.wallet.get(userId);
            if (!identity) {
                throw new Error(`User ${userId} does not exist in the wallet`);
            }
            return identity;
        } catch (error) {
            console.error(`Failed to get user identity: ${error}`);
            throw error;
        }
    }
}

module.exports = FabricCAService;