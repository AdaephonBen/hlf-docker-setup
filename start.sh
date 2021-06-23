#!/usr/bin/env bash

echo "#################################################################################################################"
echo "Cleaning up artifacts before starting..."
echo "#################################################################################################################"

docker-compose down
sudo rm -rf /tmp/hyperledger

echo "#################################################################################################################"
echo "Pulling all docker images..."
echo "#################################################################################################################"

docker-compose pull
docker pull hyperledger/fabric-ccenv:1.4.4
docker tag hyperledger/fabric-ccenv:1.4.4 hyperledger/fabric-ccenv:latest

echo "#################################################################################################################"
echo "Starting TLS Server..."
echo "#################################################################################################################"

docker-compose up -d ca-tls
sleep 5

echo "#################################################################################################################"
echo "Enrolling TLS CA Admin..."
echo "#################################################################################################################"

sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger

export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/tls/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/tls/ca/admin

fabric-ca-client enroll -d -u https://tls-ca-admin:tls-ca-adminpw@0.0.0.0:7052

echo "#################################################################################################################"
echo "Registering Peers and Ordering Service with the TLS CA..."
echo "#################################################################################################################"

for i in {1..4}
do
	for j in {0..1}
	do
		fabric-ca-client register -d --id.name peer${i}-org${j} --id.secret peer${i}pw --id.type peer -u https://0.0.0.0:7052
	done
done
fabric-ca-client register -d --id.name orderer1-org0 --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7052

echo "#################################################################################################################"
echo "Setting up Org0's CA..."
echo "#################################################################################################################"

docker-compose up -d rca-org0
sleep 5

echo "#################################################################################################################"
echo "Enrolling Org0's CA Admin..."
echo "#################################################################################################################"

sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger

export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/ca/admin

fabric-ca-client enroll -d -u https://rca-org0-admin:rca-org0-adminpw@0.0.0.0:7053
fabric-ca-client register -d --id.name orderer1-org0 --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7053
fabric-ca-client register -d --id.name admin-org0 --id.secret org0adminpw --id.type user -u https://0.0.0.0:7053

for i in {1..4}
do
	fabric-ca-client register -d --id.name peer${i}-org0 --id.secret peer${i}pw --id.type peer -u https://0.0.0.0:7053
done

echo "#################################################################################################################"
echo "Setting up Org1's CA..."
echo "#################################################################################################################"

docker-compose up -d rca-org1
sleep 5

echo "#################################################################################################################"
echo "Enrolling Org1's CA Admin..."
echo "#################################################################################################################"

sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger

export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/ca/admin

fabric-ca-client enroll -d -u https://rca-org1-admin:rca-org1-adminpw@0.0.0.0:7054

fabric-ca-client register -d --id.name admin-org1 --id.secret org1adminpw --id.type user -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name user-org1 --id.secret org1userpw --id.type user -u https://0.0.0.0:7054

for i in {1..4}
do
	fabric-ca-client register -d --id.name peer${i}-org1 --id.secret peer${i}pw --id.type peer -u https://0.0.0.0:7054
done

echo "#################################################################################################################"
echo "Enrolling all peers..."
echo "#################################################################################################################"

for j in {1..4}
do
	mkdir -p /tmp/hyperledger/org0/peer$j/assets/ca
	cp /tmp/hyperledger/org0/ca/admin/msp/cacerts/0-0-0-0-7053.pem /tmp/hyperledger/org0/peer$j/assets/ca/org0-ca-cert.pem
	
	export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/peer$j
	export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/peer$j/assets/ca/org0-ca-cert.pem
	export FABRIC_CA_CLIENT_MSPDIR=msp
	
	fabric-ca-client enroll -d -u https://peer$j-org0:peer${j}pw@0.0.0.0:7053
	
	mkdir -p /tmp/hyperledger/org0/peer$j/assets/tls-ca
	cp /tmp/hyperledger/tls/ca/admin/msp/cacerts/0-0-0-0-7052.pem /tmp/hyperledger/org0/peer$j/assets/tls-ca/tls-ca-cert.pem
	
	export FABRIC_CA_CLIENT_MSPDIR=tls-msp
	export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/peer$j/assets/tls-ca/tls-ca-cert.pem
	
	fabric-ca-client enroll -d -u https://peer$j-org0:peer${j}pw@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer$j-org0
	
	cp /tmp/hyperledger/org0/peer$j/tls-msp/keystore/*_sk /tmp/hyperledger/org0/peer$j/tls-msp/keystore/key.pem 
done

for j in {1..4}
do
	mkdir -p /tmp/hyperledger/org1/peer$j/assets/ca
	cp /tmp/hyperledger/org1/ca/admin/msp/cacerts/0-0-0-0-7054.pem /tmp/hyperledger/org1/peer$j/assets/ca/org1-ca-cert.pem
	
	export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer$j
	export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer$j/assets/ca/org1-ca-cert.pem
	export FABRIC_CA_CLIENT_MSPDIR=msp
	
	fabric-ca-client enroll -d -u https://peer$j-org1:peer${j}pw@0.0.0.0:7054
	
	mkdir -p /tmp/hyperledger/org1/peer$j/assets/tls-ca
	cp /tmp/hyperledger/tls/ca/admin/msp/cacerts/0-0-0-0-7052.pem /tmp/hyperledger/org1/peer$j/assets/tls-ca/tls-ca-cert.pem
	
	export FABRIC_CA_CLIENT_MSPDIR=tls-msp
	export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer$j/assets/tls-ca/tls-ca-cert.pem
	
	fabric-ca-client enroll -d -u https://peer$j-org1:peer${j}pw@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer$j-org1
	
	cp /tmp/hyperledger/org1/peer$j/tls-msp/keystore/*_sk /tmp/hyperledger/org1/peer$j/tls-msp/keystore/key.pem 
done

echo "#################################################################################################################"
echo "Enrolling all admins..."
echo "#################################################################################################################"

sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/peer1/assets/ca/org0-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://admin-org0:org0adminpw@0.0.0.0:7053

for j in {1..4}
do
	mkdir -p /tmp/hyperledger/org0/peer$j/msp/admincerts
	cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/peer$j/msp/admincerts/org0-admin-cert.pem
done
mkdir -p /tmp/hyperledger/org0/admin/msp/admincerts
cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/admin/msp/admincerts/org0-admin-cert.pem
mkdir -p /tmp/hyperledger/org0/orderer/msp/admincerts
cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/orderer/msp/admincerts/orderer-admin-cert.pem

export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp

fabric-ca-client enroll -d -u https://admin-org1:org1adminpw@0.0.0.0:7054

for j in {1..4}
do
	mkdir -p /tmp/hyperledger/org1/peer$j/msp/admincerts
	cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer$j/msp/admincerts/org1-admin-cert.pem
done
mkdir -p /tmp/hyperledger/org1/admin/msp/admincerts
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/admin/msp/admincerts/org1-admin-cert.pem

echo "#################################################################################################################"
echo "Starting all peers..."
echo "#################################################################################################################"

for i in {0..1}
do
	for j in {1..4}
	do
		docker-compose up -d peer$j-org$i
	done
done
sleep 5

echo "#################################################################################################################"
echo "Enrolling Ordering Service..."
echo "#################################################################################################################"

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

fabric-ca-client enroll -d -u https://orderer1-org0:ordererpw@0.0.0.0:7052 --enrollment.profile tls --csr.hosts orderer1-org0

cp /tmp/hyperledger/org0/orderer/tls-msp/keystore/*_sk /tmp/hyperledger/org0/orderer/tls-msp/keystore/key.pem

echo "#################################################################################################################"
echo "Setting up MSP Directory Structure for both Organizations..."
echo "#################################################################################################################"

mkdir -p /tmp/hyperledger/org0/msp/{admincerts,cacerts,tlscacerts,users}
cp /tmp/hyperledger/org0/orderer/assets/ca/org0-ca-cert.pem /tmp/hyperledger/org0/msp/cacerts/
cp /tmp/hyperledger/org0/orderer/assets/tls-ca/tls-ca-cert.pem /tmp/hyperledger/org0/msp/tlscacerts/
cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/msp/admincerts/admin-org0-cert.pem

mkdir -p /tmp/hyperledger/org1/msp/{admincerts,cacerts,tlscacerts,users}
cp /tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem /tmp/hyperledger/org1/msp/cacerts/
cp /tmp/hyperledger/org1/peer1/assets/tls-ca/tls-ca-cert.pem /tmp/hyperledger/org1/msp/tlscacerts/
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/msp/admincerts/admin-org1-cert.pem

echo "#################################################################################################################"
echo "Generating Genesis Block..."
echo "#################################################################################################################"

configtxgen -profile OrgsOrdererGenesis -outputBlock /tmp/hyperledger/org0/orderer/channel.block -channelID syschannel
configtxgen -profile OrgsChannel -outputCreateChannelTx /tmp/hyperledger/org0/orderer/channel.tx -channelID mychannel

echo "#################################################################################################################"
echo "Starting Ordering Service..."
echo "#################################################################################################################"

docker-compose up -d orderer1-org0

echo "#################################################################################################################"
echo "Starting CLIs..."
echo "#################################################################################################################"

docker-compose up -d cli-org0
docker-compose up -d cli-org1
sleep 5

echo "#################################################################################################################"
echo "Copying channel to peers..."
echo "#################################################################################################################"

cp /tmp/hyperledger/org0/orderer/channel.tx /tmp/hyperledger/org0/peer1/assets/channel.tx
cp /tmp/hyperledger/org0/orderer/channel.tx /tmp/hyperledger/org1/peer1/assets/channel.tx
cp /tmp/hyperledger/org0/orderer/channel.block /tmp/hyperledger/org0/peer1/assets/channel.block
cp /tmp/hyperledger/org0/orderer/channel.block /tmp/hyperledger/org1/peer1/assets/channel.block

echo "#################################################################################################################"
echo "Setting up dummy AI module..."
echo "#################################################################################################################"

docker-compose up -d mock

echo "#################################################################################################################"
echo "Complete!"
echo "#################################################################################################################"
