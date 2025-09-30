// Browser-compatible encryption utilities
export class VoteEncryption {
    constructor(electionPublicKeyPem) {
        this.electionPublicKeyPem = electionPublicKeyPem;
    }

    async importRsaPublicKey(pem) {
        const pemBody = pem.replace(/-----BEGIN PUBLIC KEY-----/, '')
            .replace(/-----END PUBLIC KEY-----/, '')
            .replace(/\s+/g, '');
        const binaryDer = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0));
        return await crypto.subtle.importKey(
            'spki',
            binaryDer.buffer,
            {
                name: 'RSA-OAEP',
                hash: 'SHA-256'
            },
            false,
            ['encrypt']
        );
    }

    async encryptVote(vote) {
        try {
            const voteData = new TextEncoder().encode(JSON.stringify(vote));
            const publicKey = await this.importRsaPublicKey(this.electionPublicKeyPem);
            const ciphertext = await crypto.subtle.encrypt({ name: 'RSA-OAEP' }, publicKey, voteData);
            const encryptedVote = btoa(String.fromCharCode(...new Uint8Array(ciphertext)));

            const hashBuffer = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(encryptedVote));
            const hashArray = Array.from(new Uint8Array(hashBuffer));
            const ballotHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

            return { encryptedVote, ballotHash };
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