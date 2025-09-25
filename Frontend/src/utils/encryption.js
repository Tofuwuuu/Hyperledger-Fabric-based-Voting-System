import { publicEncrypt, constants } from 'crypto';

export class VoteEncryption {
    constructor(electionPublicKey) {
        this.electionPublicKey = electionPublicKey;
    }

    encryptVote(vote) {
        try {
            // Convert vote to JSON string
            const voteData = JSON.stringify(vote);
            
            // Encrypt using election public key
            const encryptedVote = publicEncrypt(
                {
                    key: this.electionPublicKey,
                    padding: constants.RSA_PKCS1_OAEP_PADDING,
                    oaepHash: 'sha256'
                },
                Buffer.from(voteData)
            );

            // Create ballot hash
            const ballotHash = crypto.createHash('sha256')
                .update(encryptedVote)
                .digest('hex');

            return {
                encryptedVote: encryptedVote.toString('base64'),
                ballotHash
            };
        } catch (error) {
            console.error('Error encrypting vote:', error);
            throw new Error('Failed to encrypt vote');
        }
    }
}

export const verifyBallotHash = (encryptedVote, ballotHash) => {
    try {
        const computedHash = crypto.createHash('sha256')
            .update(Buffer.from(encryptedVote, 'base64'))
            .digest('hex');
        
        return computedHash === ballotHash;
    } catch (error) {
        console.error('Error verifying ballot hash:', error);
        throw new Error('Failed to verify ballot hash');
    }
};