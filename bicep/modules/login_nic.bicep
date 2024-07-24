param region string
param numberOfInstances int
param subnetId string

resource loginPIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = [ for i in range(1, numberOfInstances): {
  name: 'login${i}PIP'
  location: region
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}]

resource loginNIC 'Microsoft.Network/networkInterfaces@2019-11-01' = [ for i in range(1, numberOfInstances): {
  name: 'login${i}NIC'
  location: region
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: loginPIP[i - 1].id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}]

output count int = numberOfInstances
output ids array = [for i in range(0, numberOfInstances): loginNIC[i].id]
output public_ips array = [for i in range(0, numberOfInstances): loginPIP[i].properties.ipAddress]
