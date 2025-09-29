import React, { useState } from 'react';
import {
    Container,
    Typography,
    Card,
    CardContent,
    TextField,
    Button,
    Box,
    Alert,
    CircularProgress,
    Grid
} from '@mui/material';
import { useNavigate } from 'react-router-dom';

const Admin = () => {
    const [voterId, setVoterId] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const navigate = useNavigate();

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        navigate('/');
    };

    const handleRegisterVoter = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setSuccess('');

        try {
            const token = localStorage.getItem('token');
            const response = await fetch('http://localhost:3001/api/voter/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ voterId }),
            });

            const data = await response.json();

            if (data.success) {
                setSuccess('Voter registered successfully!');
                setVoterId('');
            } else {
                setError(data.message || 'Failed to register voter');
            }
        } catch (err) {
            setError('Failed to connect to server');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Container>
            <Box display="flex" justifyContent="space-between" alignItems="center" style={{ marginTop: '2rem', marginBottom: '2rem' }}>
                <Typography variant="h4">
                    Admin Panel
                </Typography>
                <Button onClick={handleLogout} variant="outlined">
                    Logout
                </Button>
            </Box>

            <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Register Voter
                            </Typography>
                            
                            {error && (
                                <Alert severity="error" style={{ marginBottom: '1rem' }}>
                                    {error}
                                </Alert>
                            )}

                            {success && (
                                <Alert severity="success" style={{ marginBottom: '1rem' }}>
                                    {success}
                                </Alert>
                            )}

                            <form onSubmit={handleRegisterVoter}>
                                <TextField
                                    label="Voter ID"
                                    value={voterId}
                                    onChange={(e) => setVoterId(e.target.value)}
                                    fullWidth
                                    variant="outlined"
                                    margin="normal"
                                    required
                                />

                                <Button
                                    type="submit"
                                    variant="contained"
                                    color="primary"
                                    fullWidth
                                    disabled={loading}
                                    style={{ marginTop: '1rem' }}
                                >
                                    {loading ? <CircularProgress size={24} /> : 'Register Voter'}
                                </Button>
                            </form>
                        </CardContent>
                    </Card>
                </Grid>

                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Quick Actions
                            </Typography>
                            
                            <Box display="flex" flexDirection="column" gap={2}>
                                <Button
                                    variant="outlined"
                                    onClick={() => navigate('/results')}
                                    fullWidth
                                >
                                    View Results
                                </Button>
                                
                                <Button
                                    variant="outlined"
                                    onClick={() => window.open('http://localhost:3001/api/health', '_blank')}
                                    fullWidth
                                >
                                    Check API Health
                                </Button>
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>
            </Grid>
        </Container>
    );
};

export default Admin;
