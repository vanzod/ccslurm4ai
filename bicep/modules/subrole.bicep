targetScope = 'subscription'

@description('The principal to assign the role to')
param principalId string

@allowed([
  'owner'
  'contributor'
  'reader'
])
@description('Built-in role to assign')
param roleType string

var role = {
  owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

resource roleAssignSub 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, principalId, role[roleType])
  properties: {
    roleDefinitionId: role[roleType]
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
