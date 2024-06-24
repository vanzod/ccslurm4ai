param region string
param config object

resource bastionNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'bastionNSG'
  location: region
  properties: {
    securityRules: config.bastion_nsg_rules
  }
}

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
          networkSecurityGroup: sub.name == 'AzureBastionSubnet' ? { id: bastionNSG.id }: null
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
