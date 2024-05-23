param region string
param subnetIds object
param allowedIpRange string
@secure()
param config object

var anfAccountName = substring('${config.accountName}-${uniqueString(resourceGroup().id)}', 0, 16)

resource anfAccount 'Microsoft.NetApp/netAppAccounts@2022-11-01' = {
  name: anfAccountName
  location: region
  properties: {}
}

resource sharedPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2022-11-01' = {
  name: config.poolName
  location: region
  parent: anfAccount
  properties: {
    serviceLevel: config.serviceLevel
    size: config.CapacityTiB * 1024 * 1024 * 1024 * 1024
  }
}

resource sharedVolume 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2022-11-01' = {
  name: config.volumeName
  location: region
  parent: sharedPool
  properties: {
    creationToken: 'shared'
    serviceLevel: config.serviceLevel
    subnetId: subnetIds[config.subnetName]
    protocolTypes: config.protocolTypes
    securityStyle: 'unix'
    unixPermissions: '0777'
    usageThreshold: config.CapacityTiB * 1024 * 1024 * 1024 * 1024
    exportPolicy: {
      rules: [
        {
            ruleIndex: 1
            unixReadOnly: false
            unixReadWrite: true
            cifs: false
            nfsv3: false
            nfsv41: true
            allowedClients: allowedIpRange
            kerberos5ReadOnly: false
            kerberos5ReadWrite: false
            kerberos5iReadOnly: false
            kerberos5iReadWrite: false
            kerberos5pReadOnly: false
            kerberos5pReadWrite: false
            hasRootAccess: true
            chownMode: 'Unrestricted'
        }
      ]
    }
  }
}

output sharedIP string = sharedVolume.properties.mountTargets[0].ipAddress
