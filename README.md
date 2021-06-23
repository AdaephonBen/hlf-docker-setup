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
docker exec -it cli-org0 bash
```
Run the following commands in `cli-org0`.
```bash
export CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/org0/admin/msp
peer channel create -c mychannel -f /tmp/hyperledger/org0/peer1/assets/channel.tx -o orderer1-org0:7050 --outputBlock /tmp/hyperledger/org0/peer1/assets/channel.block --tls --cafile /tmp/hyperledger/org0/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

for i in {1..4}
do
	CORE_PEER_ADDRESS=peer$i-org0:7051 peer channel join -b /tmp/hyperledger/org0/peer1/assets/channel.block
done
```
Run the following command on the host system. 
```bash
sudo cp /tmp/hyperledger/org0/peer1/assets/channel.block /tmp/hyperledger/org1/peer1/assets/channel.block
```
```bash
docker exec -it cli-org1 bash
```
Run the following commands in `cli-org1`.
```bash
export CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/org1/admin/msp

for i in {1..4}
do
	CORE_PEER_ADDRESS=peer$i-org1:7051 peer channel join -b /tmp/hyperledger/org1/peer1/assets/channel.block
done
```


### To install and instantiate Chaincode (Run on CLI)

```bash
docker exec -it cli-org0 bash
```
Run the following commands in `cli-org0`.
```bash
cd ../../..
mkdir adaephonben
cd adaephonben
git clone https://github.com/adaephonben/junction-project-chaincode
export CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/org0/admin/msp

for i in {1..4}
do
	CORE_PEER_ADDRESS=peer$i-org0:7051 peer chaincode install -n jp -v 1.0 -p github.com/adaephonben/junction-project-chaincode
done
```
```bash
docker exec -it cli-org1 bash
```
Run the following commands in `cli-org1`.
```bash
cd ../../..
mkdir adaephonben
cd adaephonben
git clone https://github.com/adaephonben/junction-project-chaincode
export CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/org1/admin/msp

for i in {1..4}
do
	CORE_PEER_ADDRESS=peer$i-org1:7051 peer chaincode install -n jp -v 1.0 -p github.com/adaephonben/junction-project-chaincode
done

peer chaincode instantiate -C mychannel -n jp -v 1.0 -c '{"Args":[]}' -o orderer1-org0:7050 --tls --cafile /tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem
```

### To execute the chaincode

```bash
docker exec -it cli-org0 bash
```
Run the following commands in `cli-org0`.
```bash
peer chaincode invoke -C mychannel -n jp -c '{"Args":["register-event","A2","2.3","3.4","43.2","fff","1623167816","Danger"]}'  --peerAddresses peer1-org0:7051  --tlsRootCertFiles /tmp/hyperledger/org0/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem  --peerAddresses peer2-org0:7051  --tlsRootCertFiles /tmp/hyperledger/org0/peer2/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem  --peerAddresses peer3-org0:7051  --tlsRootCertFiles /tmp/hyperledger/org0/peer3/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem  --peerAddresses peer4-org0:7051  --tlsRootCertFiles /tmp/hyperledger/org0/peer4/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem  --peerAddresses peer1-org1:7051  --tlsRootCertFiles /tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem  --peerAddresses peer2-org1:7051  --tlsRootCertFiles /tmp/hyperledger/org1/peer2/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem  --peerAddresses peer3-org1:7051  --tlsRootCertFiles /tmp/hyperledger/org1/peer3/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem  --peerAddresses peer4-org1:7051  --tlsRootCertFiles /tmp/hyperledger/org1/peer4/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem -o orderer1-org0:7050 --tls --cafile /tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem
```
```bash
peer chaincode query -C mychannel -n jp -c '{"Args":["get-event","A2"]}'
```
