@description('Required. Name of the Static Web App.')
@maxLength(40)
param name string

@description('Required. Azure location of the Static Web App (region).')
param location string

@description('Optional. Tags to apply to the resource.')
param tags object = {}

@description('Optional. SKU for the Static Web App.')
@allowed([
  'Free'
  'Standard'
])
param sku string = 'Free'

@description('Optional. Whether to enable managed identity on the Static Web App.')
param enableManagedIdentity bool = true

//@description('Optional. Custom domain(s) to add to the Static Web App.')
//param customDomains array = []

resource swa 'Microsoft.Web/staticSites@2023-12-01' = {
  name: name
  location: location
  sku: {
    name: sku
    tier: sku
  }
  tags: tags
  identity: enableManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    repositoryToken: ''
    allowConfigFileUpdates: true
  }
}

@description('The resource ID of the Static Web App')
output resourceId string = swa.id

@description('The default hostname of the Static Web App')
output defaultHostname string = swa.properties.defaultHostname

@description('The principalId of the system-assigned identity (if enabled)')
output principalId string = enableManagedIdentity && contains(swa.identity, 'principalId') ? swa.identity.principalId : ''
