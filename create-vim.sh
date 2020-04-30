#!/usr/bin/env sh

# Global parameters. Change as appropriate to your own setup
GROUP=cmpu3055-lab2
VM=${1:-cmpu3055-lab2-vm}
DIR=2020-cmpu3055-lab2
REPO=https://github.com/bjg/${DIR}.git
PORT=5000

# Create, if not exists, the resourse group
if ! az group list | grep -q ${GROUP}; then
    az group create --name ${GROUP} --location eastus > /dev/null
fi

# create, if not exists, the target vm
if ! az vm list | grep -q ${VM}; then
  az vm create --resource-group ${GROUP} \
    --name ${VM} \
    --image UbuntuLTS \
    --generate-ssh-keys \
    --output json \
    --verbose > /dev/null
fi

# gather the network info we'll need to connect
NIC_ID=$(
  az vm show -n ${VM} -g ${GROUP} \
    --query 'networkProfile.networkInterfaces[].id' \
    -o tsv
)

read -d '' IP_ID SUBNET_ID <<< $(
  az network nic show \
    --ids ${NIC_ID} \
    --query '[ipConfigurations[].publicIpAddress.id, ipConfigurations[].subnet.id]' \
    -o tsv
)

VM_IP_ADDR=$(
  az network public-ip show --ids ${IP_ID} \
    --query ipAddress \
    -o tsv
)

# Open the firewall port we need
az vm open-port --resource-group ${GROUP} --name ${VM} --port ${PORT}


# Install any software dependencies on remote target
ssh ${VM_IP_ADDR} 'sudo apt-get update && sudo apt-get install -y python3 python3-pip git && pip3 install flask'

# Clone or update the repo
ssh ${VM_IP_ADDR} "[ -d ${DIR} ] || git clone ${REPO}"
ssh ${VM_IP_ADDR} "[ -d ${DIR} ] && cd ${DIR}; git pull ${REPO}"

# Start the server on the remote target
ssh ${VM_IP_ADDR} "cd ${DIR}; FLASK_APP=status.py nohup python3 -m flask run --host 0.0.0.0 --port ${PORT} &"

# Print a ready-made command for getting the target status
echo "curl -X GET http://${VM_IP_ADDR}/status"

