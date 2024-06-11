param region string
@secure()
param config object
param kvName string
param subnetId string
param vnetName string
param vnetId string

var dbName = substring('slurmacctdb-${uniqueString(resourceGroup().id)}', 0, 20)

resource mySqlDb 'Microsoft.DBforMySQL/flexibleServers@2023-06-30' = {
  name: dbName
  location: region
  sku: {
    name: config.sku
    tier: config.tier
  }
  properties: {
    version: '8.0.21'
    administratorLogin: config.dbAdminUsername
    administratorLoginPassword: config.dbAdminPwd
    createMode: 'Default'
    network: {
      publicNetworkAccess: 'Disabled'
    }
    backup: {
      backupRetentionDays: 35
      geoRedundantBackup: 'Disabled'
    }
    storage:{
      autoGrow: 'Enabled'
      storageSizeGB: 20
    }
  }
}

// Set innodb_lock_wait_timeout to Slurm recommended value
resource innoDbLockWait 'Microsoft.DBforMySQL/flexibleServers/configurations@2023-06-30' = {
  name: 'innodb_lock_wait_timeout'
  parent: mySqlDb
  properties: {
    value: '900'
  }
}

module publicKeyKVStore 'create_kv_secret.bicep' = {
  name: 'mySqlAdminPwdKVStore'
  params: {
    kvName: kvName
    secretName: '${config.dbAdminUsername}-MySqlPwd'
    secretValue: config.dbAdminPwd
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = {
  name: '${dbName}-PE'
  location: region
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${dbName}-private-connection'
        properties: {
          privateLinkServiceId: mySqlDb.id
          groupIds: [
            'mysqlServer'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

var privateLinkName = 'privatelink.mysql.database.azure.com'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateLinkName
  location: 'global'
}

resource privateDnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: vnetName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateLinkName
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output fqdn string = mySqlDb.properties.fullyQualifiedDomainName
output user string = mySqlDb.properties.administratorLogin
