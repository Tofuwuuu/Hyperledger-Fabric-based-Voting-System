#!/bin/bash

function initCouchDBIndices() {
    CHANNEL_NAME="votingchannel"
    CC_NAME="votingcc"
    
    # Create indices for voter queries
    VOTER_INDEX=$(cat << EOF
{
    "index": {
        "fields": ["docType", "voterID", "hasVoted"]
    },
    "ddoc": "voterIndexDoc",
    "name": "voterIndex",
    "type": "json"
}
EOF
)

    # Create indices for ballot queries
    BALLOT_INDEX=$(cat << EOF
{
    "index": {
        "fields": ["docType", "ballotHash", "timestamp"]
    },
    "ddoc": "ballotIndexDoc",
    "name": "ballotIndex",
    "type": "json"
}
EOF
)

    # Push indices to CouchDB
    curl -X POST http://admin:adminpw@localhost:5984/${CHANNEL_NAME}_${CC_NAME}/_index \
        -H "Content-Type: application/json" \
        -d "${VOTER_INDEX}"

    curl -X POST http://admin:adminpw@localhost:5984/${CHANNEL_NAME}_${CC_NAME}/_index \
        -H "Content-Type: application/json" \
        -d "${BALLOT_INDEX}"
}