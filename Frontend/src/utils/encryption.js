// Browser-compatible encryption utilities
export class VoteEncryption {
    constructor(electionPublicKey) {
        this.electionPublicKey = electionPublicKey;
    }

    async encryptVote(vote) {
        try {
            // Convert vote to JSON string
            const voteData = JSON.stringify(vote);
            
            // For demo purposes, we'll use a simple encoding
            // In production, you would use proper RSA encryption
            const encryptedVote = btoa(voteData); // Base64 encoding

            // Create ballot hash using Web Crypto API
            const data = new TextEncoder().encode(encryptedVote);
            const hashBuffer = await crypto.subtle.digest('SHA-256', data);
            const hashArray = Array.from(new Uint8Array(hashBuffer));
            const ballotHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

            return {
                encryptedVote,
                ballotHash
            };
        } catch (error) {
            console.error('Error encrypting vote:', error);
            throw new Error('Failed to encrypt vote');
        }
    }
}

export const verifyBallotHash = async (encryptedVote, ballotHash) => {
    try {
        const data = new TextEncoder().encode(encryptedVote);
        const hashBuffer = await crypto.subtle.digest('SHA-256', data);
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        const computedHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
        
        return computedHash === ballotHash;
    } catch (error) {
        console.error('Error verifying ballot hash:', error);
        throw new Error('Failed to verify ballot hash');
    }
};