targetScope = 'subscription'

param region string
param rgName string
param config object
param principalObjId string
param roleDefinitionIds object
param subnetIds object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: rgName
}

module workspaceGrafana 'managed_prometheus_grafana.bicep' = {
  name: 'workspaceGrafana'
  scope: resourceGroup
  params: {
    region: region
    principalObjId: principalObjId
    roleDefinitionIds: roleDefinitionIds
  }
}

module generateIngestionEndpointUrl 'ingestion_endpoint.bicep' = {
  name: 'generateIngestionEndpointUrl'
  scope: resourceGroup
  params: {
    dceResourceId: workspaceGrafana.outputs.dataCollectionEndpointResourceId
    dcrResourceId: workspaceGrafana.outputs.dataCollectionRuleResourceId
  }
  dependsOn: [
    workspaceGrafana
  ]
}

module prometheusScraper 'prometheus_scraper.bicep' = {
  name: 'prometheusScraper'
  scope: resourceGroup
  params: {
    region: region
    config: config
    subnetIds: subnetIds
  }
}

output dataCollectionRuleId string = workspaceGrafana.outputs.dataCollectionRuleResourceId
output monitorMetricsIngestionEndpoint string = generateIngestionEndpointUrl.outputs.metricsIngestionEndpoint
output prometheusVmId string = prometheusScraper.outputs.id
output prometheusVmPrincipalId string = prometheusScraper.outputs.principalId
output prometheusVmIp string = prometheusScraper.outputs.privateIp
output prometheusVmAdmin string = prometheusScraper.outputs.adminUsername
output grafanaName string = workspaceGrafana.outputs.grafanaName
