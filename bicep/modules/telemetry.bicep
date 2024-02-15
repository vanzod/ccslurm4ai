param region string
param config object
param principalObjId string
param roleDefinitionIds object
param subnetIds object

module workspaceGrafana 'managed_prometheus_grafana.bicep' = {
  name: 'workspaceGrafana'
  params: {
    region: region
    principalObjId: principalObjId
    roleDefinitionIds: roleDefinitionIds
  }
}

module generateIngestionEndpointUrl 'ingestion_endpoint.bicep' = {
  name: 'generateIngestionEndpointUrl'
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
  params: {
    region: region
    config: config
    subnetIds: subnetIds
  }
  dependsOn: [
    workspaceGrafana
  ]
}

output monitorMetricsIngestionEndpoint string = generateIngestionEndpointUrl.outputs.metricsIngestionEndpoint

output prometheusVmId string = prometheusScraper.outputs.id
output prometheusVmIp string = prometheusScraper.outputs.privateIp
output prometheusVmAdmin string = prometheusScraper.outputs.adminUsername
