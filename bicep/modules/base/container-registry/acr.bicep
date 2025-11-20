@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param name string

@description('Provide a location for the registry.')
param location string

@description('Provide a tier of your Azure Container Registry. Default is: Basic')
@allowed([ 'Basic', 'Standard', 'Premium'])
param acrSku string = 'Premium'

@description('Enable Admin Login. Default is: False')
param adminUserEnabled bool = false

@description('Enable publicNetworkAccess. Default is: disabled')
param publicNetworkAccess string = 'Disabled'

@description('Optional. Tags of the resource.')
param tags object = {}


resource acrResource 'Microsoft.ContainerRegistry/registries@2023-08-01-preview' = {
  name: name
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
      networkRuleSet: {
      defaultAction: 'Deny'
      publicNetworkAccess: publicNetworkAccess
    }
  }
  tags: tags
}

@description('Output the login server property')
output loginServer string = acrResource.properties.loginServer
@description('Output the acr id')
output Id string = acrResource.id
@description('Output the acr name')
output name string = acrResource.name
