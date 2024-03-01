using './main.bicep'

param region = readEnvironmentVariable('REGION', '')
param rgName = readEnvironmentVariable('RESOURCE_GROUP', '')
param deployingUserObjId = readEnvironmentVariable('USER_OBJECTID', '')

param vnetConfig = {
  name: 'clusterVnet'
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

param anfConfig = {
  accountName: 'ccslurmANF'
  poolName: 'sharedpool'
  volumeName: 'shared'
  subnetName: 'anf'
  CapacityTiB: 4
  serviceLevel: 'Premium'
  protocolTypes: [
    'NFSv4.1'
  ]
}

param cyclecloudConfig = {
  vmSize: 'Standard_D4s_v4'
  subnetName: 'infra'
  imageVersion: '8.6.020240223'
  cycleAdminUsername: 'cycleadmin'
  sshPublicKey: loadTextContent('../cycleadmin_id_rsa.pub')
  sshPrivateKey: loadTextContent('../cycleadmin_id_rsa')
}

param prometheusConfig = {
  vmSize: 'Standard_D4s_v4'
  subnetName: 'infra'
  vmImage: {
    publisher: 'almalinux'
    offer: 'almalinux-x86_64'
    sku: '8_7-gen2'
    version: '8.7.2023072701'
  }
  adminUsername: 'cycleadmin'
  sshPublicKey: loadTextContent('../cycleadmin_id_rsa.pub')
  sshPrivateKey: loadTextContent('../cycleadmin_id_rsa')
}

param MySqlConfig = {
  sku: 'Standard_D2ads_v5'
  tier: 'GeneralPurpose'
  dbAdminUsername: 'cycleadmin'
  dbAdminPwd: loadTextContent('../mysql_admin_pwd.txt')
}

param roleDefinitionIds = {
  GrafanaAdmin: '22926164-76b3-42b3-bc55-97df8dab3e41'
  MonitoringMetricsPublisher: '3913510d-42f4-4e42-8a64-420c390055eb'
  MonitoringDataReader: 'b0d8363b-8ddd-447d-831f-62ca05bff136'
}
