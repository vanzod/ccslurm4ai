param region string
param config object

resource nsgs 'Microsoft.Network/networkSecurityGroups@2024-01-01' = [for nsg in config.nsgs: {
  name: nsg.name
  location: region
  properties: {
    securityRules: nsg.rules
  }
}]

// Create a dictionary of NSG IDs for easy lookup
var nsgsIds = [for i in range(0, length(config.nsgs)): {
  name: nsgs[i].name
  id: nsgs[i].id
}]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: config.name
  location: region
  properties: {
    addressSpace: {
      addressPrefixes: [
        config.ipRange
      ]
    }
    subnets: [for sub in config.subnets: {
        name: sub.name
        properties: {
          addressPrefix: sub.ipRange
          delegations: sub.delegations
          networkSecurityGroup: {
            #disable-next-line use-resource-id-functions
            id: filter(nsgsIds, nsg => nsg.name == sub.nsg)[0].id
          }
        }
    }]
  }
}

output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
output subnetIds object = reduce(
  map(
    config.subnets,
    subnet => {
      '${subnet.name}': filter(
        virtualNetwork.properties.subnets, (s) => s.name == subnet.name
      )[0].id
    }
  ),
  {},
  (cur, next) => union(cur, next)
)
