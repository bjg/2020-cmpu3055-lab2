#!/usr/bin/env sh

GROUP=cmpu3055-lab2
VM=cmpu3055-lab2-vm

if ! az group list | grep -q ${GROUP}; then
    az group create --name ${GROUP} --location eastus > /dev/null
fi

if ! az vm list | grep -q ${VM}; then
  az vm create --resource-group ${GROUP} \
    --name ${VM} \
    --image UbuntuLTS \
    --generate-ssh-keys \
    --output json \
    --verbose > /dev/null
fi

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

echo ${VM_IP_ADDR}

