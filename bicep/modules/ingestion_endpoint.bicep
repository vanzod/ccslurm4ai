param dceResourceId string
param dcrResourceId string

var dceName = split(dceResourceId, '/')[8]
var dceRg = split(dceResourceId, '/')[4]

resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' existing = {
  name: dceName
  scope: resourceGroup(dceRg)
}

var dcrName = split(dcrResourceId, '/')[8]
var dcrRg = split(dcrResourceId, '/')[4]

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' existing = {
  name: dcrName
  scope: resourceGroup(dcrRg)
}

var dceEndpoint = dataCollectionEndpoint.properties.metricsIngestion.endpoint
var dcrImmutableId = dataCollectionRule.properties.immutableId

output metricsIngestionEndpoint string = '${dceEndpoint}/dataCollectionRules/${dcrImmutableId}/streams/Microsoft-PrometheusMetrics/api/v1/write?api-version=2023-04-24'
