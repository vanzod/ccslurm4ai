using './main.bicep'

param vnetConfig = {
  name: 'ndv5testVnet'
  ipRange: '10.64.0.0/14'
  subnets: [
    {
      name: 'compute'
      ipRange: '10.64.0.0/16'
      delegations: []
    }
    {
      name: 'anf'
      ipRange: '10.67.0.0/22'
      delegations: [
        {
          name: 'anf'
          properties: {
            serviceName: 'Microsoft.Netapp/volumes'
          }
        }
      ]
    }
    {
      name: 'infra'
      ipRange: '10.67.4.0/22'
      delegations: []
    }
    {
      name: 'AzureBastionSubnet'
      ipRange: '10.67.8.0/22'
      delegations: []
    }
  ]
}

param kvConfig = {
  allowedUserObjID: readEnvironmentVariable('USER_OBJECTID', '')
}

param cyclecloudConfig = {
  vmSize: 'Standard_D4as_v4'
  subnetName: 'infra'
  imageVersion: '8.4.020230411'
  adminUsername: 'cycleadmin'
  sshPublicKey: loadTextContent('../cycleadmin_id_rsa.pub')
  sshPrivateKey: loadTextContent('../cycleadmin_id_rsa')
}

