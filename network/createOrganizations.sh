#!/bin/bash

function createOrganizations() {
  # Create Auditor Org
  infoln "Creating Auditor Organization"
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/auditor.example.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-auditor --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"
  { set +x; } 2>/dev/null

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
  fabric-ca-client register --caname ca-auditor --id.name peer0 --id.secret peer0pw --id.type peer --id.attrs "role=peer:ecert"
  
  # Register admin
  fabric-ca-client register --caname ca-auditor --id.name auditorAdmin --id.secret auditorAdminpw --id.type admin --id.attrs "hf.Registrar.Roles=*,hf.Registrar.Attributes=*"

  # Generate peer0 MSP
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/msp" --csr.hosts peer0.auditor.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  # Generate peer0 TLS certificates
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls" --enrollment.profile tls --csr.hosts peer0.auditor.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  # Copy TLS certs to proper locations
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/server.key"

  # Generate admin MSP
  fabric-ca-client enroll -u https://auditorAdmin:auditorAdminpw@localhost:7054 --caname ca-auditor -M "${PWD}/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/auditor/ca-cert.pem"

  # Copy config.yaml to appropriate locations
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/msp/config.yaml"
  cp "${PWD}/organizations/peerOrganizations/auditor.example.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp/config.yaml"
}

infoln() {
    printf "%s\n" "$*"
}

createOrganizations