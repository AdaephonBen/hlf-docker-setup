#!/usr/bin/env bash
docker-compose down
sudo rm -rf /tmp/hyperledger

docker-compose up -d ca-tls
sleep 5

sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger

export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/tls/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/tls/ca/admin

fabric-ca-client enroll -d -u https://tls-ca-admin:tls-ca-adminpw@0.0.0.0:7052

fabric-ca-client register -d --id.name peer1-org1 --id.secret peer1PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name peer2-org1 --id.secret peer2PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name orderer1-org0 --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7052

docker-compose up -d rca-org0
sleep 5

sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger

export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/ca/admin

fabric-ca-client enroll -d -u https://rca-org0-admin:rca-org0-adminpw@0.0.0.0:7053
fabric-ca-client register -d --id.name orderer1-org0 --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7053
fabric-ca-client register -d --id.name admin-org0 --id.secret org0adminpw --id.type user -u https://0.0.0.0:7053

docker-compose up -d rca-org1
sleep 5

sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger

export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/ca/admin

fabric-ca-client enroll -d -u https://rca-org1-admin:rca-org1-adminpw@0.0.0.0:7054

fabric-ca-client register -d --id.name peer1-org1 --id.secret peer1PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name peer2-org1 --id.secret peer2PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name admin-org1 --id.secret org1AdminPW --id.type user -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name user-org1 --id.secret org1UserPW --id.type user -u https://0.0.0.0:7054

mkdir -p /tmp/hyperledger/org1/peer1/assets/ca
cp /tmp/hyperledger/org1/ca/admin/msp/cacerts/0-0-0-0-7054.pem /tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://peer1-org1:peer1PW@0.0.0.0:7054

mkdir -p /tmp/hyperledger/org1/peer1/assets/tls-ca
cp /tmp/hyperledger/tls/ca/admin/msp/cacerts/0-0-0-0-7052.pem /tmp/hyperledger/org1/peer1/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://peer1-org1:peer1PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer1-org1

cp /tmp/hyperledger/org1/peer1/tls-msp/keystore/*_sk /tmp/hyperledger/org1/peer1/tls-msp/keystore/key.pem 
mkdir -p /tmp/hyperledger/org1/peer2/assets/ca
cp /tmp/hyperledger/org1/ca/admin/msp/cacerts/0-0-0-0-7054.pem /tmp/hyperledger/org1/peer2/assets/ca/org1-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer2
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer2/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://peer2-org1:peer2PW@0.0.0.0:7054

mkdir -p /tmp/hyperledger/org1/peer2/assets/tls-ca
cp /tmp/hyperledger/tls/ca/admin/msp/cacerts/0-0-0-0-7052.pem /tmp/hyperledger/org1/peer2/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer2/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://peer2-org1:peer2PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer2-org1

cp /tmp/hyperledger/org1/peer2/tls-msp/keystore/*_sk /tmp/hyperledger/org1/peer2/tls-msp/keystore/key.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://admin-org1:org1AdminPW@0.0.0.0:7054

mkdir -p /tmp/hyperledger/org1/peer1/msp/admincerts
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer1/msp/admincerts/org1-admin-cert.pem
mkdir -p /tmp/hyperledger/org1/peer2/msp/admincerts
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer2/msp/admincerts/org1-admin-cert.pem
mkdir -p /tmp/hyperledger/org1/admin/msp/admincerts
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/admin/msp/admincerts/org1-admin-cert.pem

docker-compose up -d peer1-org1
docker-compose up -d peer2-org1
sleep 5

mkdir -p /tmp/hyperledger/org0/orderer/assets/ca
cp /tmp/hyperledger/org0/ca/admin/msp/cacerts/0-0-0-0-7053.pem /tmp/hyperledger/org0/orderer/assets/ca/org0-ca-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer/assets/ca/org0-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://orderer1-org0:ordererpw@0.0.0.0:7053

mkdir -p /tmp/hyperledger/org0/orderer/assets/tls-ca
cp /tmp/hyperledger/tls/ca/admin/msp/cacerts/0-0-0-0-7052.pem /tmp/hyperledger/org0/orderer/assets/tls-ca/tls-ca-cert.pem

export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer/assets/tls-ca/tls-ca-cert.pem

fabric-ca-client enroll -d -u https://orderer1-org0:ordererPW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts orderer1-org0

cp /tmp/hyperledger/org0/orderer/tls-msp/keystore/*_sk /tmp/hyperledger/org0/orderer/tls-msp/keystore/key.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer/assets/ca/org0-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://admin-org0:org0adminpw@0.0.0.0:7053

mkdir /tmp/hyperledger/org0/orderer/msp/admincerts
cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/orderer/msp/admincerts/orderer-admin-cert.pem

mkdir -p /tmp/hyperledger/org0/msp/{admincerts,cacerts,tlscacerts,users}
cp /tmp/hyperledger/org0/orderer/assets/ca/org0-ca-cert.pem /tmp/hyperledger/org0/msp/cacerts/
cp /tmp/hyperledger/org0/orderer/assets/tls-ca/tls-ca-cert.pem /tmp/hyperledger/org0/msp/tlscacerts/
cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/msp/admincerts/admin-org0-cert.pem

mkdir -p /tmp/hyperledger/org1/msp/{admincerts,cacerts,tlscacerts,users}
cp /tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem /tmp/hyperledger/org1/msp/cacerts/
cp /tmp/hyperledger/org1/peer1/assets/tls-ca/tls-ca-cert.pem /tmp/hyperledger/org1/msp/tlscacerts/
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/msp/admincerts/admin-org1-cert.pem

configtxgen -profile OrgsOrdererGenesis -outputBlock /tmp/hyperledger/org0/orderer/genesis.block -channelID syschannel
configtxgen -profile OrgsChannel -outputCreateChannelTx /tmp/hyperledger/org0/orderer/channel.tx -channelID mychannel

docker-compose up -d orderer1-org0

docker-compose up -d cli-org1

sleep 5

cp /tmp/hyperledger/org0/orderer/channel.tx /tmp/hyperledger/org1/peer1/assets/channel.tx

echo "Complete!"
