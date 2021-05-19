# Docker Setup
[Reference](https://hyperledger-fabric-ca.readthedocs.io/en/latest/operations_guide.html)

### Add `fabric-ca-client` to $PATH
Change the path appropriately and append command to `.profile` to persist changes to $PATH. 
```bash
export PATH=/path/containing/fabric-ca-client/binary:$PATH
```

### To setup the entire network
Use the script `start.sh`. Make sure it's run with root permissions. 
```
sudo ./start.sh
```

### To join the peers to the channel

```bash
docker exec -it cli-org1 bash
```
Run the following commands in `cli-org1`.
```bash

export CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/org1/admin/msp
peer channel create -c mychannel -f /tmp/hyperledger/org1/peer1/assets/channel.tx -o orderer1-org0:7050 --outputBlock /tmp/hyperledger/org1/peer1/assets/mychannel.block --tls --cafile /tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

export CORE_PEER_ADDRESS=peer1-org1:7051
peer channel join -b /tmp/hyperledger/org1/peer1/assets/mychannel.block

export CORE_PEER_ADDRESS=peer2-org1:7051
peer channel join -b /tmp/hyperledger/org1/peer1/assets/mychannel.block
```

### To install and instantiate Chaincode (Run on CLI)

```bash
docker exec -it cli-org1 bash
```
Run the following commands in `cli-org1`.
```bash
cd ../../..
mkdir adaephonben
cd adaephonben
git clone https://github.com/adaephonben/junction-project-chaincode

CORE_PEER_ADDRESS=peer1-org1:7051 peer chaincode install -n jp -v 1.0 -p github.com/adaephonben/junction-project-chaincode
CORE_PEER_ADDRESS=peer2-org1:7051 peer chaincode install -n jp -v 1.0 -p github.com/adaephonben/junction-project-chaincode

peer chaincode instantiate -C mychannel -n jp -v 1.0 -c '{"Args":[]}' -o orderer1-org0:7050 --tls --cafile /tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem -P "OutOf(4, 'Org1.member', 'Org1.member', 'Org1.member', 'Org1.member', 'Org2.member', 'Org2.member', 'Org2.member', 'Org2.member')"
```

### To execute the chaincode

```bash
docker exec -it cli-org1 bash
```
Run the following commands in `cli-org1`.
```bash

```
