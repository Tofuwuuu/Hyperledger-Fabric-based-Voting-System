import React, { useMemo, useEffect, useState } from 'react';
import { Container, Card, CardContent, Typography, Button, Box } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { electionApi } from '../utils/api';

const Verify = () => {
  const navigate = useNavigate();
  const ballotHash = useMemo(() => localStorage.getItem('ballotHash') || '', []);
  const [recordedHash, setRecordedHash] = useState('');

  useEffect(() => {
    const fetchVerify = async () => {
      try {
        const res = await electionApi.getVerify();
        const data = res.data;
        if (data?.success) {
          setRecordedHash(data.voter?.ballotHash || '');
        }
      } catch (_) {}
    };
    fetchVerify();
  }, []);

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
          {recordedHash && (
            <>
              <Typography variant="subtitle2" color="textSecondary" style={{ marginTop: '1rem' }}>Recorded On-Chain Hash</Typography>
              <Typography variant="body1" style={{ wordBreak: 'break-all' }}>
                {recordedHash}
              </Typography>
            </>
          )}
        </CardContent>
      </Card>
    </Container>
  );
};

export default Verify;



