param region string
param subnetId string

resource bastionPIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: 'bastionPIP'
  location: region
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2023-02-01' = {
  name: 'bastion'
  location: region
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: bastionPIP.id
          }
        }
      }
    ]
  }
}

output name string = bastionHost.name
