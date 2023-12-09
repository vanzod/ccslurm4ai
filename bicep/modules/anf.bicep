param region string
param subnetId string
param allowedIpRange string

resource anfAccount 'Microsoft.NetApp/netAppAccounts@2022-11-01' = {
  name: 'ANF-ndv5'
  location: region
  properties: {}
}

resource sharedPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2022-11-01' = {
  name: 'sharedpool'
  location: region
  parent: anfAccount
  properties: {
    serviceLevel: 'Premium'
    size: 4 * 1024 * 1024 * 1024 * 1024
  }
}

resource sharedVolume 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2022-11-01' = {
  name: 'shared'
  location: region
  parent: sharedPool
  properties: {
    creationToken: 'shared'
    serviceLevel: 'Premium'
    subnetId: subnetId
    protocolTypes: [
      'NFSv4.1'
    ]
    securityStyle: 'unix'
    usageThreshold: 4 * 1024 * 1024 * 1024 * 1024
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
