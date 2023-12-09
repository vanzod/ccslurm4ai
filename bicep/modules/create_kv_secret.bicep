param kvName string
param secretName string

@secure()
param secretValue string

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: kvName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: secretName
  parent: kv
  properties: {
    value: secretValue
  }
}
