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

param anfConfig = {
  accountName: 'ccslurmANF'
  poolName: 'sharedpool'
  volumeName: 'shared'
  subnetName: 'anf'
  CapacityTiB: 4
  serviceLevel: 'Standard'
  protocolTypes: [
    'NFSv4.1'
  ]
}

param cyclecloudConfig = {
  vmSize: 'Standard_D4as_v4'
  subnetName: 'infra'
  imageVersion: '8.5.02023120'
  cycleAdminUsername: 'cycleadmin'
  sshPublicKey: loadTextContent('../cycleadmin_id_rsa.pub')
  sshPrivateKey: loadTextContent('../cycleadmin_id_rsa')
}

param MySqlConfig = {
  sku: 'Standard_D2ads_v5'
  tier: 'GeneralPurpose'
  dbAdminUsername: 'cycleadmin'
  dbAdminPwd: loadTextContent('../mysql_admin_pwd.txt')
}
