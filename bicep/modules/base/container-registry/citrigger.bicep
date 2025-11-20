param appServiceName string
param containerRegistryName string
param location string

@description('Container Registry Webhook Name')
param containerRegistryWebhookName string

@description('Optional. Tags of the resource.')
param tags object = {}

resource publishingcreds 'Microsoft.Web/sites/config@2022-09-01' existing = {
  name: '${appServiceName}/publishingcredentials'
}

var webhookUri = publishingcreds.list().properties.scmUri

module acrhook '../container-registry/acr-hook.bicep' = {
  name: 'acrhook-${uniqueString(resourceGroup().id)}'
  params: {
    name: containerRegistryWebhookName
    acrName: containerRegistryName
    location: location
    tags: tags
    status: 'enabled'
    hookServiceUri: '${webhookUri}/api/registry/webhook'
    actions: [
      'push'
    ]
    scope: '${appServiceName}:latest'
  }
}
