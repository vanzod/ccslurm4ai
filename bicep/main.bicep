targetScope = 'subscription'

param region string
param rgName string
param vnetConfig object
@secure()
param cyclecloudConfig object
@secure()
param prometheusConfig object
param anfConfig object
@secure()
param MySqlConfig object
param roleDefinitionIds object
param deployingUserObjId string
param rg_tags object
param monitor_tags object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: region
  tags: rg_tags
}

module clusterNetwork 'modules/network.bicep' = {
  name: 'clusterNetwork'
  scope: resourceGroup
  params: {
    region: region
    config: vnetConfig
  }
}

module KeyVault 'modules/keyvault.bicep' = {
  name: 'KeyVault'
  scope: resourceGroup
  params: {
    region: region
    allowedUserObjID: deployingUserObjId
  }
}

module CycleCloud 'modules/cyclecloud.bicep' = {
  name: 'CycleCloud'
  scope: resourceGroup
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
  scope: resourceGroup
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
  scope: resourceGroup
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
  scope: resourceGroup
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
  scope: resourceGroup
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

module telemetryInfra 'modules/telemetry.bicep' = {
  name: 'telemetryInfra'
  params: {
    region: region
    rgName: rgName
    config: prometheusConfig
    roleDefinitionIds: roleDefinitionIds
    principalObjId: deployingUserObjId
    subnetIds: clusterNetwork.outputs.subnetIds
    monitor_tags: monitor_tags
  }
  dependsOn: [
    resourceGroup
    clusterNetwork
  ]
}

module moneoMetrics 'modules/moneo_metric_rules.bicep' = {
  name: 'moneoMetrics'
  scope: resourceGroup
  params: {
    region: region
    monitorWorkspaceId: telemetryInfra.outputs.monitorWorkspaceId
  }
  dependsOn: [
    telemetryInfra
  ]
}

output globalVars object = {
  anfSharedIP: ANF.outputs.sharedIP
  bastionName: bastion.outputs.name
  cycleserverName: CycleCloud.outputs.name
  cycleserverId: CycleCloud.outputs.id
  cycleserverAdmin: CycleCloud.outputs.adminUser
  clusterSubnetName: 'compute'
  keyVaultName: KeyVault.outputs.name
  lockerAccountName: CycleCloud.outputs.lockerSAName
  region: region
  resourceGroup: resourceGroup.name
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
  prometheusVmId: telemetryInfra.outputs.prometheusVmId
  prometheusVmPrincipalId: telemetryInfra.outputs.prometheusVmPrincipalId
  dataCollectionRuleId: telemetryInfra.outputs.dataCollectionRuleId
  monitorMetricsIngestionEndpoint: telemetryInfra.outputs.monitorMetricsIngestionEndpoint
  managedGrafanaName: telemetryInfra.outputs.grafanaName
}

output ansible_inventory object = {
  all: {
    hosts: {
      cycleserver: {
        ansible_host: CycleCloud.outputs.privateIp
        ansible_user: CycleCloud.outputs.adminUser
      }
      prometheus: {
        ansible_host: telemetryInfra.outputs.prometheusVmIp
        ansible_user: telemetryInfra.outputs.prometheusVmAdmin
      }
    }
  }
}

