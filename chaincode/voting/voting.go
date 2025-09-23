package main

import (
    "encoding/json"
    "fmt"
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
}

// Candidate represents an election candidate
type Candidate struct {
    CandidateID string `json:"candidateID"`
    VoteCount   int    `json:"voteCount"`
}

// RegisterVoter adds a new voter to the world state
func (c *VotingContract) RegisterVoter(ctx contractapi.TransactionContextInterface, voterID string) error {
    voter := Voter{
        VoterID:  voterID,
        HasVoted: false,
    }
    
    voterJSON, err := json.Marshal(voter)
    if err != nil {
        return fmt.Errorf("failed to marshal voter: %v", err)
    }

    return ctx.GetStub().PutState(voterID, voterJSON)
}

// CastVote records a vote for a candidate
func (c *VotingContract) CastVote(ctx contractapi.TransactionContextInterface, voterID string, candidateID string) error {
    // Get the voter
    voterBytes, err := ctx.GetStub().GetState(voterID)
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
    candidateBytes, err := ctx.GetStub().GetState(candidateID)
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
    voterJSON, err := json.Marshal(voter)
    if err != nil {
        return fmt.Errorf("failed to marshal voter: %v", err)
    }

    // Update the world state
    err = ctx.GetStub().PutState(candidateID, candidateJSON)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(voterID, voterJSON)
}

// QueryResults gets the current vote count for a candidate
func (c *VotingContract) QueryResults(ctx contractapi.TransactionContextInterface, candidateID string) (*Candidate, error) {
    candidateBytes, err := ctx.GetStub().GetState(candidateID)
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