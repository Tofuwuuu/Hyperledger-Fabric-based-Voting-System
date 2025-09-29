import React, { useMemo } from 'react';
import { Container, Card, CardContent, Typography, Button, Box } from '@mui/material';
import { useNavigate } from 'react-router-dom';

const Verify = () => {
  const navigate = useNavigate();
  const ballotHash = useMemo(() => localStorage.getItem('ballotHash') || '', []);

  return (
    <Container>
      <Box display="flex" justifyContent="space-between" alignItems="center" style={{ marginTop: '2rem', marginBottom: '2rem' }}>
        <Typography variant="h4">Verify Your Ballot</Typography>
        <Button variant="outlined" onClick={() => navigate('/vote')}>Back to Voting</Button>
      </Box>
      <Card>
        <CardContent>
          <Typography variant="body1" gutterBottom>
            Save this ballot hash to independently verify your vote was recorded.
          </Typography>
          <Typography variant="subtitle2" color="textSecondary">Ballot Hash</Typography>
          <Typography variant="body1" style={{ wordBreak: 'break-all' }}>
            {ballotHash || 'No ballot hash found. Cast a vote first.'}
          </Typography>
        </CardContent>
      </Card>
    </Container>
  );
};

export default Verify;


