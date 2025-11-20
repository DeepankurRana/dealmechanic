
@description('The name of the webhook')
param name string

@description('The name of the container registry')
param acrName string

@description('The hook service URI')
param hookServiceUri string

@description('Location of the webhook.')
param location string

@description('The scope of repositories where the even will be triggered')
param scope string

@description('Resource tags that we might need to add to all resources (i.e. Environment, Cost center, application name etc)')
param tags object

@description('The list of actions that trigger the webhook to post notifications.')
@allowed([
  'chart_delete'
  'chart_push'
  'delete'
  'push'
  'quarantine'
])
param actions array

@allowed([
'disabled'
'enabled'
])
@description('The status of the webhook at the time the operation was called.')
param status string = 'enabled'

resource acr 'Microsoft.ContainerRegistry/registries@2023-08-01-preview' existing = {
  name: acrName
}

resource hook 'Microsoft.ContainerRegistry/registries/webhooks@2023-08-01-preview' = {
  location: location
  parent: acr
  name: name 
  tags: tags
  properties: {
    serviceUri: hookServiceUri
    status: status
    actions: actions
    scope: scope
  }
}
