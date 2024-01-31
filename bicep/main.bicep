param region string = resourceGroup().location
param vnetConfig object
param kvConfig object
param cyclecloudConfig object
param anfConfig object
param MySqlConfig object
param roleDefinitionIds object

module clusterNetwork 'modules/network.bicep' = {
  name: 'clusterNetwork'
  params: {
    region: region
    config: vnetConfig
  }
}

module KeyVault 'modules/keyvault.bicep' = {
  name: 'KeyVault'
  params: {
    region: region
    config: kvConfig
  }
}

module CycleCloud 'modules/cyclecloud.bicep' = {
  name: 'CycleCloud'
  params: {
    region: region
    config: cyclecloudConfig
    subnetIds: clusterNetwork.outputs.subnetIds
    kvName: KeyVault.outputs.name
  }
  dependsOn: [
    clusterNetwork
    KeyVault
  ]
}

module ANF 'modules/anf.bicep' = {
  name: 'ANF'
  params: {
    region: region
    subnetIds: clusterNetwork.outputs.subnetIds
    allowedIpRange: vnetConfig.ipRange
    config: anfConfig
  }
  dependsOn: [
    clusterNetwork
  ]
}

module bastion 'modules/bastion.bicep' = {
  name: 'bastion'
  params: {
    region: region
    subnetId: clusterNetwork.outputs.subnetIds.AzureBastionSubnet
  }
  dependsOn: [
    clusterNetwork
  ]
}

module loginNIC 'modules/login_nic.bicep' = {
  name: 'loginNIC'
  params: {
    region: region
    subnetId: clusterNetwork.outputs.subnetIds.compute
    numberOfInstances: 3
  }
  dependsOn: [
    clusterNetwork
  ]
}

module MySql 'modules/mysql.bicep' = {
  name: 'MySql'
  params: {
    region: region
    config: MySqlConfig
    kvName: KeyVault.outputs.name
    vnetName: clusterNetwork.outputs.vnetName
    vnetId: clusterNetwork.outputs.vnetId
    subnetId: clusterNetwork.outputs.subnetIds.compute
  }
  dependsOn: [
    clusterNetwork
    KeyVault
  ]
}

module PrometheusGrafana 'modules/prometheus_grafana.bicep' = {
  name: 'PromeheusGrafana'
  params: {
    region: region
    roleDefinitionIds: roleDefinitionIds
  }
}

output globalVars object = {
  anfSharedIP: ANF.outputs.sharedIP
  bastionName: bastion.outputs.name
  cycleserverName: CycleCloud.outputs.name
  cycleserverId: CycleCloud.outputs.id
  cycleserverAdmin: CycleCloud.outputs.adminUser
  cycleserverAdminPubKey: CycleCloud.outputs.adminPublicKey
  clusterSubnetName: 'compute'
  keyVaultName: KeyVault.outputs.name
  lockerAccountName: CycleCloud.outputs.lockerSAName
  region: region
  resourceGroup: resourceGroup().name
  subscriptionId: subscription().subscriptionId
  subscriptionName: subscription().displayName
  tenantId: subscription().tenantId
  vnetName: clusterNetwork.outputs.vnetName
  mySqlFqdn: MySql.outputs.fqdn
  mySqlUser: MySql.outputs.user
  mySqlPwd: MySqlConfig.dbAdminPwd
  loginNicsCount: loginNIC.outputs.count
  loginNicsId: loginNIC.outputs.ids
  loginNicsPublicIP: loginNIC.outputs.public_ips
}

output ansible_inventory object = {
  all: {
    hosts: {
      cycleserver: {
        ansible_host: CycleCloud.outputs.privateIp
        ansible_user: CycleCloud.outputs.adminUser
      }
    }
  }

}
