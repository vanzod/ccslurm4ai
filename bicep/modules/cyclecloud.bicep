param region string
@secure()
param config object
param subnetIds object
param kvName string

var lockerSAName = substring('cclockersa${uniqueString(resourceGroup().id)}', 0, 16)
var ccServerName = 'cycleserver'
var contributorID = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource cycleserverNSG 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'cycleserverNSG'
  location: region
//  properties: {
//    securityRules: [
//      {
//        name: 'SSH'
//        properties: {
//          priority: 1000
//          protocol: 'Tcp'
//          access: 'Allow'
//          direction: 'Inbound'
//          sourceAddressPrefixes: config.inboundAllowedIPs
//          sourcePortRange: '*'
//          destinationAddressPrefix: '*'
//          destinationPortRange: '22'
//        }
//      }
//      {
//        name: 'HTTP'
//        properties: {
//          priority: 1001
//          protocol: 'Tcp'
//          access: 'Allow'
//          direction: 'Inbound'
//          sourceAddressPrefixes: config.inboundAllowedIPs
//          sourcePortRange: '*'
//          destinationAddressPrefix: '*'
//          destinationPortRange: '80'
//        }
//      }
//      {
//        name: 'HTTPS'
//        properties: {
//          priority: 1002
//          protocol: 'Tcp'
//          access: 'Allow'
//          direction: 'Inbound'
//          sourceAddressPrefixes: config.inboundAllowedIPs
//          sourcePortRange: '*'
//          destinationAddressPrefix: '*'
//          destinationPortRange: '443'
//       }
//      }
//    ]
//  }
}

resource cycleserverPIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'cycleserverPIP'
  location: region
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource cycleserverNIC 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: 'cycleserverNIC'
  location: region
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: cycleserverPIP.id
          }
          subnet: {
            id: subnetIds[config.subnetName]
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: cycleserverNSG.id
    }
  }
}

resource cycleserver 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: ccServerName
  location: region
  properties: {
    hardwareProfile: {
      vmSize: config.vmSize
    }
    storageProfile: {
      osDisk: {
        name: 'cycleserverOSDisk'
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'azurecyclecloud'
        offer: 'azure-cyclecloud'
        sku: 'cyclecloud8-gen2'
        version: config.imageVersion
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: cycleserverNIC.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      computerName: 'cycleserver'
      adminUsername: config.cycleAdminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${config.cycleAdminUsername}/.ssh/authorized_keys'
              keyData: config.sshPublicKey
            }
          ]
        }
      }
    }
  }
  plan: {
    name: 'cyclecloud8-gen2'
    publisher: 'azurecyclecloud'
    product: 'azure-cyclecloud'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

module privateKeyKVStore 'create_kv_secret.bicep' = {
  name: 'privateKeyKVStore'
  params: {
    kvName: kvName
    secretName: '${config.cycleAdminUsername}-SshPrivateKey'
    secretValue: config.sshPrivateKey
  }
}

module publicKeyKVStore 'create_kv_secret.bicep' = {
  name: 'publicKeyKVStore'
  params: {
    kvName: kvName
    secretName: '${config.cycleAdminUsername}-SshPublicKey'
    secretValue: config.sshPublicKey
  }
}

resource rgContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(ccServerName, contributorID, resourceGroup().id, subscription().id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: resourceId('microsoft.authorization/roleDefinitions', contributorID)
    principalId: cycleserver.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module subReadAssignment './subrole.bicep' = {
  name: substring('subReadAssignment_${uniqueString(resourceGroup().id)}', 0, 25)
  scope: subscription()
  params: {
    principalId: cycleserver.identity.principalId
    roleType: 'reader'
  }
}

resource lockerAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: lockerSAName
  location: region
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
  }
}

resource lockerBlobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: lockerAccount
}

resource lockerContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: 'cyclecloud'
  parent: lockerBlobService
  properties: {
    publicAccess: 'None'
  }
}

output name string = cycleserver.name
output id string = cycleserver.id
output adminUser string = cycleserver.properties.osProfile.adminUsername
output privateIp string = cycleserverNIC.properties.ipConfigurations[0].properties.privateIPAddress
output lockerSAName string = lockerAccount.name
