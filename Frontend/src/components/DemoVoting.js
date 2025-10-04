import React, { useState, useEffect } from 'react';
import './DemoVoting.css';

const DemoVoting = () => {
    const [voterId, setVoterId] = useState('Voter1');
    const [candidates, setCandidates] = useState([]);
    const [results, setResults] = useState(null);
    const [selectedCandidate, setSelectedCandidate] = useState('');
    const [message, setMessage] = useState('');
    const [loading, setLoading] = useState(false);
    const [blockchainStatus, setBlockchainStatus] = useState('checking');

    useEffect(() => {
        checkHealth();
        loadCandidates();
    }, []);

    const checkHealth = async () => {
        try {
            const response = await fetch('http://localhost:3001/api/health');
            const data = await response.json();
            setBlockchainStatus(data.fabric.connected ? 'connected' : 'demo');
        } catch (error) {
            setBlockchainStatus('demo');
        }
    };

    const loadCandidates = async () => {
        try {
            const response = await fetch('http://localhost:3001/api/candidates');
            const data = await response.json();
            if (data.success) {
                setCandidates(data.candidates);
            }
        } catch (error) {
            console.error('Error loading candidates:', error);
        }
    };

    const registerVoter = async () => {
        if (!voterId.trim()) {
            setMessage('Please enter a voter ID');
            return;
        }

        setLoading(true);
        try {
            const response = await fetch('http://localhost:3001/api/voter/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ voterId: voterId.trim() })
            });

            const data = await response.json();
            setMessage(data.message);
        } catch (error) {
            setMessage('Error registering voter: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    const castVote = async () => {
        if (!selectedCandidate) {
            setMessage('Please select a candidate');
            return;
        }

        setLoading(true);
        try {
            const response = await fetch('http://localhost:3001/api/vote/cast', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ 
                    voterId: voterId.trim(),
                    candidateId: selectedCandidate
                })
            });

            const data = await response.json();
            setMessage(data.message);
            if (data.success) {
                setSelectedCandidate('');
                loadResults();
            }
        } catch (error) {
            setMessage('Error casting vote: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    const loadResults = async () => {
        try {
            const response = await fetch('http://localhost:3001/api/results');
            const data = await response.json();
            if (data.success) {
                setResults(data.results);
            }
        } catch (error) {
            console.error('Error loading results:', error);
        }
    };

    const seedCandidates = async () => {
        setLoading(true);
        try {
            const response = await fetch('http://localhost:3001/api/candidates/seed', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    candidates: [
                        { id: '1', name: 'Alice Johnson', party: 'Democratic Party' },
                        { id: '2', name: 'Bob Smith', party: 'Republican Party' },
                        { id: '3', name: 'Carol Davis', party: 'Independent' }
                    ]
                })
            });

            const data = await response.json();
            setMessage(data.message);
            if (data.success) {
                loadCandidates();
            }
        } catch (error) {
            setMessage('Error seeding candidates: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="demo-voting">
            <div className="demo-header">
                <h1>🗳️ Blockchain Voting System Demo</h1>
                <div className={`status-indicator ${blockchainStatus}`}>
                    {blockchainStatus === 'connected' ? '🔗 Blockchain Connected' : 
                     blockchainStatus === 'demo' ? '🎭 Demo Mode' : '⏳ Checking...'}
                </div>
            </div>

            <div className="demo-content">
                <div className="demo-section">
                    <h2>Register Voter</h2>
                    <div className="input-group">
                        <input
                            type="text"
                            value={voterId}
                            onChange={(e) => setVoterId(e.target.value)}
                            placeholder="Enter Voter ID"
                        />
                        <button onClick={registerVoter} disabled={loading}>
                            {loading ? 'Registering...' : 'Register Voter'}
                        </button>
                    </div>
                </div>

                <div className="demo-section">
                    <h2>Candidates</h2>
                    <button onClick={seedCandidates} disabled={loading} className="seed-btn">
                        {loading ? 'Seeding...' : 'Seed Demo Candidates'}
                    </button>
                    <div className="candidates-list">
                        {candidates.map(candidate => (
                            <div key={candidate.id} className="candidate-card">
                                <h3>{candidate.name}</h3>
                                <p>{candidate.party}</p>
                                <button 
                                    onClick={() => setSelectedCandidate(candidate.id)}
                                    className={selectedCandidate === candidate.id ? 'selected' : ''}
                                >
                                    {selectedCandidate === candidate.id ? 'Selected' : 'Select'}
                                </button>
                            </div>
                        ))}
                    </div>
                </div>

                <div className="demo-section">
                    <h2>Cast Vote</h2>
                    <button onClick={castVote} disabled={loading || !selectedCandidate}>
                        {loading ? 'Casting...' : 'Cast Vote'}
                    </button>
                </div>

                <div className="demo-section">
                    <h2>Results</h2>
                    <button onClick={loadResults} disabled={loading}>
                        {loading ? 'Loading...' : 'Load Results'}
                    </button>
                    {results && (
                        <div className="results">
                            <h3>Total Votes: {results.totalVotes}</h3>
                            <div className="results-list">
                                {results.candidates?.map(candidate => (
                                    <div key={candidate.id} className="result-item">
                                        <span>{candidate.name}</span>
                                        <span>{candidate.votes} votes</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </div>

                {message && (
                    <div className="message">
                        {message}
                    </div>
                )}
            </div>
        </div>
    );
};

export default DemoVoting;
