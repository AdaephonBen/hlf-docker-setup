# Docker Setup
[Reference](https://hyperledger-fabric-ca.readthedocs.io/en/latest/operations_guide.html)

### Add `fabric-ca-client` to $PATH
Change the path appropriately and append command to `.profile` to persist changes to $PATH. 
```bash
export PATH=/path/containing/fabric-ca-client/binary:$PATH
```

### To run TLS CA server
```bash
docker-compose up ca-tls
```

### To enroll TLS CA's admin
Please change $USER to the current user's username. 
```bash
sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/tls/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/tls/ca/admin
fabric-ca-client enroll -d -u https://tls-ca-admin:tls-ca-adminpw@0.0.0.0:7052
```

### To register Peers and Ordering Services with the TLS CA
```bash
fabric-ca-client register -d --id.name peer1-org0 --id.secret peer1PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name peer1-org1 --id.secret peer1PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name peer2-org1 --id.secret peer2PW --id.type peer -u https://0.0.0.0:7052
fabric-ca-client register -d --id.name orderer1-org0 --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7052
```

### To setup Org0 (Orderer - Traffic Junction) CA
```bash
docker-compose up rca-org0
```

### To enroll Orderer Organization CA's Admin
```bash
sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/ca/admin
fabric-ca-client enroll -d -u https://rca-org0-admin:rca-org0-adminpw@0.0.0.0:7053
fabric-ca-client register -d --id.name orderer1-org0 --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7053
fabric-ca-client register -d --id.name admin-org0 --id.secret org0adminpw --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://0.0.0.0:7053
```

### To setup Org1 CA
```bash
docker-compose up rca-org1
```

### To enroll Org1's CA Admin
```bash
sudo chown -R $USER /tmp/hyperledger
sudo chmod -R u+rX /tmp/hyperledger
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/ca/admin
fabric-ca-client enroll -d -u https://rca-org1-admin:rca-org1-adminpw@0.0.0.0:7054
fabric-ca-client register -d --id.name peer1-org1 --id.secret peer1PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name peer2-org1 --id.secret peer2PW --id.type peer -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name admin-org1 --id.secret org1AdminPW --id.type user -u https://0.0.0.0:7054
fabric-ca-client register -d --id.name user-org1 --id.secret org1UserPW --id.type user -u https://0.0.0.0:7054
```

### To enroll Peer 1 of org1
```bash
mkdir -p /tmp/hyperledger/org1/peer1/assets/ca
cp /tmp/hyperledger/org1/ca/crypto/ca-cert.pem /tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://peer1-org1:peer1PW@0.0.0.0:7054
mkdir -p /tmp/hyperledger/org1/peer1/assets/tls-ca
cp /tmp/hyperledger/tls/ca/crypto/tls-cert.pem /tmp/hyperledger/org1/peer1/assets/tls-ca/tls-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/tls-ca/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://peer1-org1:peer1PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer1-org1
```
Go to path `/tmp/hyperledger/org1/peer1/tls-msp/keystore` and change the name of the key to `key.pem`. 

### To enroll Peer 2 of org1
```bash
mkdir -p /tmp/hyperledger/org1/peer2/assets/ca
cp /tmp/hyperledger/org1/ca/crypto/ca-cert.pem /tmp/hyperledger/org1/peer2/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/peer2
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer2/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://peer2-org1:peer2PW@0.0.0.0:7054
mkdir -p /tmp/hyperledger/org1/peer2/assets/tls-ca
cp /tmp/hyperledger/tls/ca/crypto/tls-cert.pem /tmp/hyperledger/org1/peer2/assets/tls-ca/tls-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer2/assets/tls-ca/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://peer2-org1:peer2PW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts peer2-org1
```
Go to path `/tmp/hyperledger/org1/peer2/tls-msp/keystore` and change the name of the key to `key.pem`. 

### To enroll Org1's Admin
```bash
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org1/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org1/peer1/assets/ca/org1-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://admin-org1:org1AdminPW@0.0.0.0:7054
mkdir /tmp/hyperledger/org1/peer1/msp/admincerts
mkdir /tmp/hyperledger/org1/peer2/msp/admincerts
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer1/msp/admincerts/org1-admin-cert.pem
cp /tmp/hyperledger/org1/admin/msp/signcerts/cert.pem /tmp/hyperledger/org1/peer2/msp/admincerts/org1-admin-cert.pem
```

### To launch Org1's peers
```bash
docker-compose up peer1-org1
docker-compose up peer2-org1
```

### To enroll orderer
```bash
mkdir -p /tmp/hyperledger/org0/orderer/assets/ca
cp /tmp/hyperledger/org0/ca/crypto/ca-cert.pem /tmp/hyperledger/org0/orderer/assets/ca/org0-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer/assets/ca/org0-ca-cert.pem
fabric-ca-client enroll -d -u https://orderer1-org0:ordererpw@0.0.0.0:7053
mkdir -p /tmp/hyperledger/org0/orderer/assets/tls-ca
cp /tmp/hyperledger/tls/ca/crypto/tls-cert.pem /tmp/hyperledger/org0/orderer/assets/tls-ca/tls-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer/assets/tls-ca/tls-ca-cert.pem
fabric-ca-client enroll -d -u https://orderer1-org0:ordererPW@0.0.0.0:7052 --enrollment.profile tls --csr.hosts orderer1-org0
```
Go to path `/tmp/hyperledger/org0/orderer/tls-msp/keystore` and change the name of the key to `key.pem`.

### To enroll Org0's admin
```bash
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/org0/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/org0/orderer/assets/ca/org0-ca-cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
fabric-ca-client enroll -d -u https://admin-org0:org0adminpw@0.0.0.0:7053
mkdir /tmp/hyperledger/org0/orderer/msp/admincerts
cp /tmp/hyperledger/org0/admin/msp/signcerts/cert.pem /tmp/hyperledger/org0/orderer/msp/admincerts/orderer-admin-cert.pem
```

### To setup MSP folder structure for Orgs 1 and 2
```bash
mkdir -p /tmp/hyperledger/org0/msp/admincerts
mkdir -p /tmp/hyperledger/org0/msp/cacerts
mkdir -p /tmp/hyperledger/org0/msp/tlscacerts
mkdir -p /tmp/hyperledger/org0/msp/users
cp /tmp/hyperledger/org0/ca/crypto/ca-cert.pem /tmp/hyperledger/org0/msp/admincerts/admin-org0-cert.pem
cp /tmp/hyperledger/org0/admin/msp/cacerts/0-0-0-0-7053.pem /tmp/hyperledger/org0/msp/cacerts/org0-ca-cert.pem
cp /tmp/hyperledger/tls/ca/crypto/tls-cert.pem /tmp/hyperledger/org0/msp/tlscacerts/tls-ca-cert.pem
mkdir -p /tmp/hyperledger/org1/msp/admincerts
mkdir -p /tmp/hyperledger/org1/msp/cacerts
mkdir -p /tmp/hyperledger/org1/msp/tlscacerts
mkdir -p /tmp/hyperledger/org1/msp/users
cp /tmp/hyperledger/org1/ca/crypto/ca-cert.pem /tmp/hyperledger/org1/msp/admincerts/admin-org1-cert.pem
cp /tmp/hyperledger/org1/admin/msp/cacerts/0-0-0-0-7054.pem /tmp/hyperledger/org1/msp/cacerts/org1-ca-cert.pem
cp /tmp/hyperledger/tls/ca/crypto/tls-cert.pem /tmp/hyperledger/org1/msp/tlscacerts/tls-ca-cert.pem
```

### To generate the genesis block
Build and add the `configtxgen` tool to $PATH. 
```bash
configtxgen -profile OrgsOrdererGenesis -outputBlock /tmp/hyperledger/org0/orderer/genesis.block -channelID syschannel
configtxgen -profile OrgsChannel -outputCreateChannelTx /tmp/hyperledger/org0/orderer/channel.tx -channelID mychannel
```
