import React, { useState, useEffect } from 'react';
import {
    Container,
    Typography,
    Card,
    CardContent,
    Grid,
    Button,
    CircularProgress,
    Alert,
    Box
} from '@mui/material';
import { useNavigate } from 'react-router-dom';

const Results = () => {
    const [candidates, setCandidates] = useState([]);
    const [results, setResults] = useState({});
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    useEffect(() => {
        fetchCandidates();
    }, []);

    const fetchCandidates = async () => {
        try {
            const token = localStorage.getItem('token');
            const response = await fetch('http://localhost:3001/api/candidates', {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const data = await response.json();
            if (data.success) {
                setCandidates(data.candidates);
                // Fetch results for each candidate
                fetchResultsForCandidates(data.candidates);
            }
        } catch (err) {
            setError('Failed to fetch candidates');
        }
    };

    const fetchResultsForCandidates = async (candidateList) => {
        setLoading(true);
        const resultsData = {};
        
        try {
            const token = localStorage.getItem('token');
            
            for (const candidate of candidateList) {
                try {
                    const response = await fetch(`http://localhost:3001/api/results/${candidate.id}`, {
                        headers: {
                            'Authorization': `Bearer ${token}`
                        }
                    });

                    const data = await response.json();
                    if (data.success) {
                        resultsData[candidate.id] = data.results.voteCount || 0;
                    } else {
                        resultsData[candidate.id] = 0;
                    }
                } catch (err) {
                    resultsData[candidate.id] = 0;
                }
            }
            
            setResults(resultsData);
        } catch (err) {
            setError('Failed to fetch results');
        } finally {
            setLoading(false);
        }
    };

    const handleRefresh = () => {
        fetchResultsForCandidates(candidates);
    };

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        navigate('/');
    };

    if (loading && Object.keys(results).length === 0) {
        return (
            <Container>
                <Box display="flex" justifyContent="center" style={{ marginTop: '4rem' }}>
                    <CircularProgress />
                </Box>
            </Container>
        );
    }

    return (
        <Container>
            <Box display="flex" justifyContent="space-between" alignItems="center" style={{ marginTop: '2rem', marginBottom: '2rem' }}>
                <Typography variant="h4">
                    Election Results
                </Typography>
                <Box>
                    <Button onClick={handleRefresh} style={{ marginRight: '1rem' }}>
                        Refresh Results
                    </Button>
                    <Button onClick={handleLogout} variant="outlined">
                        Logout
                    </Button>
                </Box>
            </Box>

            {error && (
                <Alert severity="error" style={{ marginBottom: '1rem' }}>
                    {error}
                </Alert>
            )}

            <Grid container spacing={3}>
                {candidates.map((candidate) => (
                    <Grid item xs={12} sm={6} md={4} key={candidate.id}>
                        <Card>
                            <CardContent>
                                <Typography variant="h6" gutterBottom>
                                    {candidate.name}
                                </Typography>
                                <Typography variant="body2" color="textSecondary" gutterBottom>
                                    {candidate.party}
                                </Typography>
                                <Typography variant="h4" color="primary">
                                    {results[candidate.id] || 0}
                                </Typography>
                                <Typography variant="body2" color="textSecondary">
                                    Votes
                                </Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                ))}
            </Grid>

            {candidates.length === 0 && (
                <Card>
                    <CardContent>
                        <Typography align="center" color="textSecondary">
                            No candidates found
                        </Typography>
                    </CardContent>
                </Card>
            )}
        </Container>
    );
};

export default Results;
