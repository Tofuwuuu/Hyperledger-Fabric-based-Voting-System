import React, { useState, useEffect } from 'react';
import { 
    Button,
    Card,
    CardContent,
    Typography,
    Container,
    Grid,
    CircularProgress,
    Snackbar,
    Box,
    Alert
} from '@mui/material';
import { VoteEncryption } from '../utils/encryption';
import { electionApi } from '../utils/api';
import { useNavigate } from 'react-router-dom';

const VotingPage = () => {
    const [candidates, setCandidates] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const navigate = useNavigate();
    const [electionPublicKey, setElectionPublicKey] = useState(null);

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        navigate('/');
    };

    useEffect(() => {
        // Fetch election public key and candidates when component mounts
        fetchElectionData();
    }, []);

    const fetchElectionData = async () => {
        try {
            setLoading(true);
            // Fetch election public key
            const keyResponse = await electionApi.getPublicKey();
            if (keyResponse.data?.success) {
                setElectionPublicKey(keyResponse.data.publicKey);
            }

            // Fetch candidates
            const candidatesResponse = await electionApi.getCandidates();
            if (candidatesResponse.data?.success) {
                setCandidates(candidatesResponse.data.candidates);
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
            const { encryptedVote, ballotHash } = await encryption.encryptVote(vote);

            // Submit vote including encrypted payload and hash
            const response = await electionApi.castVote({ candidateId, encryptedVote, ballotHash });
            const data = response.data;
            if (data?.success) {
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
            if (err.isUnauthorized) {
                navigate('/');
                return;
            }
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
            <Box display="flex" justifyContent="space-between" alignItems="center" style={{ marginTop: '2rem', marginBottom: '2rem' }}>
                <Typography variant="h4">
                    Cast Your Vote
                </Typography>
                <Button onClick={handleLogout} variant="outlined">
                    Logout
                </Button>
            </Box>
            
            <Grid container spacing={3}>
                {candidates.length === 0 && (
                    <Grid item xs={12}>
                        <Typography color="textSecondary">No candidates available.</Typography>
                    </Grid>
                )}
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