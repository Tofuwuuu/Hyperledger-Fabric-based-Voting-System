import React, { useState } from 'react';
import {
    Container,
    Paper,
    TextField,
    Button,
    Typography,
    FormControl,
    InputLabel,
    Select,
    MenuItem,
    Box,
    Alert
} from '@mui/material';
import { useNavigate } from 'react-router-dom';

const Login = () => {
    const [formData, setFormData] = useState({
        userId: '',
        password: '',
        role: 'voter'
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const handleChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value
        });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const response = await fetch('http://localhost:3001/api/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData),
            });

            const data = await response.json();

            if (data.success) {
                localStorage.setItem('token', data.token);
                localStorage.setItem('user', JSON.stringify(data.user));
                
                // Navigate based on role
                if (data.user.role === 'admin') {
                    navigate('/admin');
                } else if (data.user.role === 'voter') {
                    navigate('/vote');
                } else if (data.user.role === 'auditor') {
                    navigate('/results');
                }
            } else {
                setError(data.message || 'Login failed');
            }
        } catch (err) {
            setError('Failed to connect to server');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Container maxWidth="sm" style={{ marginTop: '4rem' }}>
            <Paper elevation={3} style={{ padding: '2rem' }}>
                <Typography variant="h4" align="center" gutterBottom>
                    Voting System Login
                </Typography>
                
                {error && (
                    <Alert severity="error" style={{ marginBottom: '1rem' }}>
                        {error}
                    </Alert>
                )}

                <form onSubmit={handleSubmit}>
                    <Box style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        <TextField
                            label="User ID"
                            name="userId"
                            value={formData.userId}
                            onChange={handleChange}
                            required
                            fullWidth
                            variant="outlined"
                        />

                        <TextField
                            label="Password"
                            name="password"
                            type="password"
                            value={formData.password}
                            onChange={handleChange}
                            required
                            fullWidth
                            variant="outlined"
                        />

                        <FormControl variant="outlined" fullWidth>
                            <InputLabel>Role</InputLabel>
                            <Select
                                name="role"
                                value={formData.role}
                                onChange={handleChange}
                                label="Role"
                            >
                                <MenuItem value="voter">Voter</MenuItem>
                                <MenuItem value="admin">Admin</MenuItem>
                                <MenuItem value="auditor">Auditor</MenuItem>
                            </Select>
                        </FormControl>

                        <Button
                            type="submit"
                            variant="contained"
                            color="primary"
                            fullWidth
                            disabled={loading}
                            style={{ marginTop: '1rem', padding: '0.75rem' }}
                        >
                            {loading ? 'Logging in...' : 'Login'}
                        </Button>
                    </Box>
                </form>

                <Box style={{ marginTop: '2rem', textAlign: 'center' }}>
                    <Typography variant="body2" color="textSecondary">
                        Demo Credentials:
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                        Admin: admin / password
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                        Voter: voter1 / password
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                        Auditor: auditor1 / password
                    </Typography>
                </Box>
            </Paper>
        </Container>
    );
};

export default Login;
