#!/bin/bash

. scripts/utils.sh

function createOrganizations() {
  # Create crypto material using fabric ca
  createOrgsUsingCA
}

function createOrgsUsingCA() {
  infoln "Enrolling the CA admin for Auditor org"
  mkdir -p organizations/peerOrganizations/auditor.example.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/auditor.example.com/
  
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-auditor --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-auditor.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-auditor.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-auditor.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-auditor.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/auditor.example.com/msp/config.yaml"

  # Register peer0
  fabric-ca-client register --caname ca-auditor --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  # Register admin
  fabric-ca-client register --caname ca-auditor --id.name admin --id.secret adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/msp" --csr.hosts peer0.auditor.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/msp/config.yaml"

  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls" --enrollment.profile tls --csr.hosts peer0.auditor.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/server.key"

  # Enroll admin
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp/config.yaml"

  # Election Commission Org
  infoln "Enrolling the CA admin for Election Commission org"
  mkdir -p organizations/peerOrganizations/electioncommission.example.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/electioncommission.example.com/
  
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-electioncommission --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-electioncommission.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-electioncommission.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-electioncommission.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-electioncommission.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/electioncommission.example.com/msp/config.yaml"

  # Register peer0
  fabric-ca-client register --caname ca-electioncommission --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  # Register admin
  fabric-ca-client register --caname ca-electioncommission --id.name admin --id.secret adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-electioncommission -M "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/msp" --csr.hosts peer0.electioncommission.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/msp/config.yaml"

  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-electioncommission -M "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls" --enrollment.profile tls --csr.hosts peer0.electioncommission.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"

  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/electioncommission.example.com/peers/peer0.electioncommission.example.com/tls/server.key"

  # Enroll admin
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-electioncommission -M "${PWD}/organizations/peerOrganizations/electioncommission.example.com/users/Admin@electioncommission.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/electioncommission/ca-cert.pem"
  cp "${PWD}/organizations/peerOrganizations/electioncommission.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/electioncommission.example.com/users/Admin@electioncommission.example.com/msp/config.yaml"
}

createOrganizations