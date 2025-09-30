package main

import (
    "encoding/json"
    "fmt"
    "strings"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// VotingContract represents our smart contract
type VotingContract struct {
    contractapi.Contract
}

// Voter represents a registered voter
type Voter struct {
    VoterID   string `json:"voterID"`
    HasVoted  bool   `json:"hasVoted"`
    VotedFor  string `json:"votedFor"`
    BallotHash string `json:"ballotHash"`
}

// Candidate represents an election candidate
type Candidate struct {
    CandidateID string `json:"candidateID"`
    Name        string `json:"name"`
    Party       string `json:"party"`
    VoteCount   int    `json:"voteCount"`
}

func voterKey(voterID string) string {
    return "voter:" + voterID
}

func candidateKey(candidateID string) string {
    return "candidate:" + candidateID
}

// CreateCandidate initializes a candidate in the world state if not exists
func (c *VotingContract) CreateCandidate(ctx contractapi.TransactionContextInterface, candidateID string, name string, party string) error {
    if strings.TrimSpace(candidateID) == "" {
        return fmt.Errorf("candidateID is required")
    }
    if strings.TrimSpace(name) == "" {
        return fmt.Errorf("name is required")
    }
    if strings.TrimSpace(party) == "" {
        return fmt.Errorf("party is required")
    }
    existsBytes, err := ctx.GetStub().GetState(candidateKey(candidateID))
    if err != nil {
        return fmt.Errorf("failed to check candidate: %v", err)
    }
    if existsBytes != nil {
        return fmt.Errorf("candidate already exists: %s", candidateID)
    }
    candidate := Candidate{CandidateID: candidateID, Name: name, Party: party, VoteCount: 0}
    candidateJSON, err := json.Marshal(candidate)
    if err != nil {
        return fmt.Errorf("failed to marshal candidate: %v", err)
    }
    return ctx.GetStub().PutState(candidateKey(candidateID), candidateJSON)
}

// GetAllCandidates returns all candidates stored under candidate: namespace
func (c *VotingContract) GetAllCandidates(ctx contractapi.TransactionContextInterface) ([]*Candidate, error) {
    results := []*Candidate{}
    iterator, err := ctx.GetStub().GetStateByRange("candidate:", "candidate;")
    if err != nil {
        return nil, fmt.Errorf("failed to get candidates: %v", err)
    }
    defer iterator.Close()
    for iterator.HasNext() {
        kv, err := iterator.Next()
        if err != nil {
            return nil, err
        }
        var candidate Candidate
        if err := json.Unmarshal(kv.Value, &candidate); err != nil {
            return nil, err
        }
        results = append(results, &candidate)
    }
    return results, nil
}

// RegisterVoter adds a new voter to the world state
func (c *VotingContract) RegisterVoter(ctx contractapi.TransactionContextInterface, voterID string) error {
    if strings.TrimSpace(voterID) == "" {
        return fmt.Errorf("voterID is required")
    }
    // Disallow duplicate registration
    existing, err := ctx.GetStub().GetState(voterKey(voterID))
    if err != nil {
        return fmt.Errorf("failed to check voter: %v", err)
    }
    if existing != nil {
        return fmt.Errorf("voter already exists: %s", voterID)
    }
    voter := Voter{
        VoterID:  voterID,
        HasVoted: false,
    }
    
    voterJSON, err := json.Marshal(voter)
    if err != nil {
        return fmt.Errorf("failed to marshal voter: %v", err)
    }

    return ctx.GetStub().PutState(voterKey(voterID), voterJSON)
}

// CastVote records a vote for a candidate
func (c *VotingContract) CastVote(ctx contractapi.TransactionContextInterface, voterID string, candidateID string) error {
    // Get the voter
    voterBytes, err := ctx.GetStub().GetState(voterKey(voterID))
    if err != nil {
        return fmt.Errorf("failed to get voter: %v", err)
    }
    if voterBytes == nil {
        return fmt.Errorf("voter does not exist: %s", voterID)
    }

    var voter Voter
    err = json.Unmarshal(voterBytes, &voter)
    if err != nil {
        return fmt.Errorf("failed to unmarshal voter: %v", err)
    }

    // Check if voter has already voted
    if voter.HasVoted {
        return fmt.Errorf("voter has already cast their vote")
    }

    // Get the candidate
    candidateBytes, err := ctx.GetStub().GetState(candidateKey(candidateID))
    if err != nil {
        return fmt.Errorf("failed to get candidate: %v", err)
    }
    if candidateBytes == nil {
        return fmt.Errorf("candidate does not exist: %s", candidateID)
    }

    var candidate Candidate
    err = json.Unmarshal(candidateBytes, &candidate)
    if err != nil {
        return fmt.Errorf("failed to unmarshal candidate: %v", err)
    }

    // Update candidate vote count
    candidate.VoteCount++
    candidateJSON, err := json.Marshal(candidate)
    if err != nil {
        return fmt.Errorf("failed to marshal candidate: %v", err)
    }

    // Update voter status
    voter.HasVoted = true
    voter.VotedFor = candidateID
    // BallotHash may be set by SubmitBallotHash in a separate tx
    voterJSON, err := json.Marshal(voter)
    if err != nil {
        return fmt.Errorf("failed to marshal voter: %v", err)
    }

    // Update the world state
    err = ctx.GetStub().PutState(candidateKey(candidateID), candidateJSON)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(voterKey(voterID), voterJSON)
}

// SubmitBallotHash stores a hash of the voter's encrypted ballot for verification
func (c *VotingContract) SubmitBallotHash(ctx contractapi.TransactionContextInterface, voterID string, ballotHash string) error {
    if strings.TrimSpace(voterID) == "" || strings.TrimSpace(ballotHash) == "" {
        return fmt.Errorf("voterID and ballotHash are required")
    }
    voterBytes, err := ctx.GetStub().GetState(voterKey(voterID))
    if err != nil {
        return fmt.Errorf("failed to get voter: %v", err)
    }
    if voterBytes == nil {
        return fmt.Errorf("voter does not exist: %s", voterID)
    }
    var voter Voter
    if err := json.Unmarshal(voterBytes, &voter); err != nil {
        return fmt.Errorf("failed to unmarshal voter: %v", err)
    }
    voter.BallotHash = ballotHash
    voterJSON, err := json.Marshal(voter)
    if err != nil {
        return fmt.Errorf("failed to marshal voter: %v", err)
    }
    return ctx.GetStub().PutState(voterKey(voterID), voterJSON)
}

// GetVoter returns a voter's record (for verification/audit)
func (c *VotingContract) GetVoter(ctx contractapi.TransactionContextInterface, voterID string) (*Voter, error) {
    voterBytes, err := ctx.GetStub().GetState(voterKey(voterID))
    if err != nil {
        return nil, fmt.Errorf("failed to get voter: %v", err)
    }
    if voterBytes == nil {
        return nil, fmt.Errorf("voter does not exist: %s", voterID)
    }
    var voter Voter
    if err := json.Unmarshal(voterBytes, &voter); err != nil {
        return nil, fmt.Errorf("failed to unmarshal voter: %v", err)
    }
    return &voter, nil
}

// QueryResults gets the current vote count for a candidate
func (c *VotingContract) QueryResults(ctx contractapi.TransactionContextInterface, candidateID string) (*Candidate, error) {
    candidateBytes, err := ctx.GetStub().GetState(candidateKey(candidateID))
    if err != nil {
        return nil, fmt.Errorf("failed to get candidate: %v", err)
    }
    if candidateBytes == nil {
        return nil, fmt.Errorf("candidate does not exist: %s", candidateID)
    }

    var candidate Candidate
    err = json.Unmarshal(candidateBytes, &candidate)
    if err != nil {
        return nil, fmt.Errorf("failed to unmarshal candidate: %v", err)
    }

    return &candidate, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&VotingContract{})
    if err != nil {
        fmt.Printf("Error creating voting chaincode: %v", err)
        return
    }

    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting voting chaincode: %v", err)
    }
}