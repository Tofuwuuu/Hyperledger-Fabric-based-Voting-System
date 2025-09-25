import React, { useState, useEffect } from 'react';
import { 
    Button,
    Card,
    CardContent,
    Typography,
    Container,
    Grid,
    CircularProgress,
    Snackbar
} from '@material-ui/core';
import { Alert } from '@material-ui/lab';
import { VoteEncryption } from '../utils/encryption';
import { useNavigate } from 'react-router-dom';

const VotingPage = () => {
    const [candidates, setCandidates] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const navigate = useNavigate();
    const [electionPublicKey, setElectionPublicKey] = useState(null);

    useEffect(() => {
        // Fetch election public key and candidates when component mounts
        fetchElectionData();
    }, []);

    const fetchElectionData = async () => {
        try {
            setLoading(true);
            // Fetch election public key
            const keyResponse = await fetch('/api/election/public-key');
            const keyData = await keyResponse.json();
            if (keyData.success) {
                setElectionPublicKey(keyData.publicKey);
            }

            // Fetch candidates
            const candidatesResponse = await fetch('/api/candidates');
            const candidatesData = await candidatesResponse.json();
            if (candidatesData.success) {
                setCandidates(candidatesData.candidates);
            }
        } catch (err) {
            setError('Failed to fetch election data');
        } finally {
            setLoading(false);
        }
    };

    const handleVote = async (candidateId) => {
        try {
            setLoading(true);
            
            // Create vote payload
            const vote = {
                candidateId,
                timestamp: new Date().toISOString()
            };

            // Encrypt vote
            const encryption = new VoteEncryption(electionPublicKey);
            const { encryptedVote, ballotHash } = encryption.encryptVote(vote);

            // Submit vote
            const response = await fetch('/api/vote/cast', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('token')}`
                },
                body: JSON.stringify({
                    encryptedVote,
                    ballotHash
                })
            });

            const data = await response.json();
            if (data.success) {
                setSuccess('Vote cast successfully!');
                // Store ballot hash for verification
                localStorage.setItem('ballotHash', ballotHash);
                // Redirect to verification page after 2 seconds
                setTimeout(() => {
                    navigate('/verify');
                }, 2000);
            } else {
                setError(data.message || 'Failed to cast vote');
            }
        } catch (err) {
            setError(err.message || 'Failed to cast vote');
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <Container>
                <Grid container justifyContent="center" style={{ marginTop: '2rem' }}>
                    <CircularProgress />
                </Grid>
            </Container>
        );
    }

    return (
        <Container>
            <Typography variant="h4" gutterBottom style={{ marginTop: '2rem' }}>
                Cast Your Vote
            </Typography>
            
            <Grid container spacing={3}>
                {candidates.map((candidate) => (
                    <Grid item xs={12} sm={6} md={4} key={candidate.id}>
                        <Card>
                            <CardContent>
                                <Typography variant="h6" gutterBottom>
                                    {candidate.name}
                                </Typography>
                                <Button
                                    variant="contained"
                                    color="primary"
                                    onClick={() => handleVote(candidate.id)}
                                    disabled={loading}
                                >
                                    Vote
                                </Button>
                            </CardContent>
                        </Card>
                    </Grid>
                ))}
            </Grid>

            <Snackbar 
                open={!!error} 
                autoHideDuration={6000} 
                onClose={() => setError('')}
            >
                <Alert onClose={() => setError('')} severity="error">
                    {error}
                </Alert>
            </Snackbar>

            <Snackbar 
                open={!!success} 
                autoHideDuration={6000} 
                onClose={() => setSuccess('')}
            >
                <Alert onClose={() => setSuccess('')} severity="success">
                    {success}
                </Alert>
            </Snackbar>
        </Container>
    );
};

export default VotingPage;