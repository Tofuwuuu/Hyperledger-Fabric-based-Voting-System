#!/bin/bash

function createAuditor() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/auditor.example.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/auditor.example.com/

  fabric-ca-client enroll -u https://admin:adminpw@ca_auditor:7054 --caname ca-auditor --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca_auditor-7054-ca-auditor.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca_auditor-7054-ca-auditor.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca_auditor-7054-ca-auditor.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca_auditor-7054-ca-auditor.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/auditor.example.com/msp/config.yaml"

  # Register peer0
  fabric-ca-client register --caname ca-auditor --id.name peer0 --id.secret peer0pw --id.type peer --id.attrs "role=peer:ecert" --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  # Register user
  fabric-ca-client register --caname ca-auditor --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  # Register the org admin
  fabric-ca-client register --caname ca-auditor --id.name auditorAdmin --id.secret auditorAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  # Generate peer0 msp
  fabric-ca-client enroll -u https://peer0:peer0pw@ca_auditor:7054 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/msp" --csr.hosts peer0.auditor.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/msp/config.yaml"

  # Generate peer0-tls certificates
  fabric-ca-client enroll -u https://peer0:peer0pw@ca_auditor:7054 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls" --enrollment.profile tls --csr.hosts peer0.auditor.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/server.key"

  # Generate the peer0 msp
  fabric-ca-client enroll -u https://auditorAdmin:auditorAdminpw@ca_auditor:7054 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp/config.yaml"
}

function createElectionCommission() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/electioncommission.example.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/electioncommission.example.com/

  fabric-ca-client enroll -u https://admin:adminpw@ca_electioncommission:8054 --caname ca-electioncommission --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca_electioncommission-8054-ca-electioncommission.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca_electioncommission-8054-ca-electioncommission.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca_electioncommission-8054-ca-electioncommission.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca_electioncommission-8054-ca-electioncommission.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/electioncommission.example.com/msp/config.yaml"

  # Register peer0
  fabric-ca-client register --caname ca-electioncommission --id.name peer0 --id.secret peer0pw --id.type peer --id.attrs "role=peer:ecert" --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  # Register user
  fabric-ca-client register --caname ca-electioncommission --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  # Register the org admin
  fabric-ca-client register --caname ca-electioncommission --id.name electioncommissionAdmin --id.secret electioncommissionAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  # Generate peer0 msp
  fabric-ca-client enroll -u https://peer0:peer0pw@ca_electioncommission:8054 --caname ca-electioncommission -M "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/msp" --csr.hosts peer0.electioncommission.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/msp/config.yaml"

  # Generate peer0-tls certificates
  fabric-ca-client enroll -u https://peer0:peer0pw@ca_electioncommission:8054 --caname ca-electioncommission -M "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls" --enrollment.profile tls --csr.hosts peer0.electioncommission.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/server.key"

  # Generate the peer0 msp
  fabric-ca-client enroll -u https://electioncommissionAdmin:electioncommissionAdminpw@ca_electioncommission:8054 --caname ca-electioncommission -M "${PWD}/organizations/peerOrganizations/electioncommission.example.com/users/Admin@electioncommission.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/electioncommission.example.com/users/Admin@electioncommission.example.com/msp/config.yaml"
}

createAuditor
createElectionCommission