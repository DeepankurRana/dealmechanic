param resourcesNaming object

@description('Required. Name of the App Service Plan.')
@minLength(1)
@maxLength(40)
param appServicePlanName string

@description('Required. Name of the web app.')
@maxLength(60)
param webAppName string

@description('Optional B1 is default. Defines the name, tier, size, family and capacity of the App Service Plan.')
@allowed([ 'B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1V3', 'P2V3', 'P3V3' ])
param sku string = 'B1'

@description('Optional. Location for all resources.')
param location string

@description('Resource tags that we might need to add to all resources (i.e. Environment, Cost center, application name etc)')
param tags object

@description('Kind of server OS of the App Service Plan')
@allowed([ 'Windows', 'Linux' ])
param webAppBaseOs string

@description('The name of an existing keyvault, that it will be used to store secrets (connection string)')
param keyvaultName string

@description('The name of an existing storage account name')
param storageAccountName string

//@description('The name of a second existing storage account name')
//param secondStorageAccountName string

@description('The name of an existing Azure Container Registry')
param acrName string

@description('The connection string of the default SQL Database')
param sqlDbConnectionString string

@description('Optional. The name of an existing log analytics workspace, if not provided a new log analytics workspace will be created.')
param logAnalyticsWSName string = ''

@description('Conditional. The name of the resource group of the log analytics workspace. Required when logAnalyticsWSName is provided')
param logAnalyticsWSRGName string = ''

//@description('Required. ID for Azure Front Door used in IP Restrictions.')
//param frontDoorId string

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
}

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

//resource secondStorage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
//  name: secondStorageAccountName
//}

resource acr 'Microsoft.ContainerRegistry/registries@2023-08-01-preview' existing = {
  name: acrName
}

var dockerImageName = 'DOCKER|${acr.properties.loginServer}/${webAppName}:latest'

module logAnalyticsws 'modules/base/log-analytics-ws.bicep' = if (empty(logAnalyticsWSName)) {
  name: 'log-${uniqueString(resourceGroup().id)}'
  params: {
    name: resourcesNaming.logAnalyticsWorkspace.name
    location: location
    tags: tags
  }
}

resource logAnalyticswsExisting 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!empty(logAnalyticsWSName)) {
  name: logAnalyticsWSName
  scope: resourceGroup(logAnalyticsWSRGName)
}

var logAnalyticsWsId = (empty(logAnalyticsWSName)) ? logAnalyticsws.outputs.logAnalyticsWsId : logAnalyticswsExisting.id

module appInsights 'modules/base/app-insights.bicep' = {
  name: 'appi-${uniqueString(resourceGroup().id)}'
  params: {
    name: resourcesNaming.applicationInsights.name
    location: location
    tags: tags
    workspaceResourceId: logAnalyticsWsId
    appInsightsType: 'web'
    kind: 'web'
  }
}

module asp 'modules/base/app-services/app-service-plan.bicep' = {
  name: 'asp-${uniqueString(resourceGroup().id)}'
  params: {
    name: appServicePlanName
    location: location
    tags: tags
    sku: sku
    serverOS: (webAppBaseOs =~ 'linux') ? 'Linux' : 'Windows'
    diagnosticWorkspaceId: logAnalyticsWsId
  }
}

module webApp 'modules/base/app-services/web-app.bicep' = {
  name: 'app-${uniqueString(resourceGroup().id)}'
  params: {
    kind: (webAppBaseOs =~ 'linux') ? 'app,linux' : 'app'
    name: webAppName
    location: location
    serverFarmResourceId: asp.outputs.resourceId
    diagnosticWorkspaceId: logAnalyticsWsId
    appInsightId: appInsights.outputs.appInsResourceId
    siteConfigSelection: (webAppBaseOs =~ 'linux') ? 'dockerLinuxNet7' : 'windowsNet7'
    dockerImageName: dockerImageName
    systemAssignedIdentity: true
    hasPrivateLink: false
    appSettingsKeyValuePairs: {
      KeyVault__VaultURI: keyvault.properties.vaultUri
      Storage__StorageURI: storage.properties.primaryEndpoints.blob
      DOCKER_CUSTOM_IMAGE_NAME: dockerImageName
      DOCKER_ENABLE_CI: 'true'
    }
    appConnectionStringsKeyValuePairs:{
      SqlServerConnection: {
        value: sqlDbConnectionString
        type: 'SQLAzure'
      }
    }
    ipSecurityRestrictions: [
      {
        ipAddress: '10.10.10.10/32'
        action: 'Allow'
        tag: 'Default'
        priority: 100
        name: 'Allow-1'
      }
      {
        ipAddress: '10.10.10.11/32'
        action: 'Allow'
        tag: 'Default'
        priority: 200
        name: 'Allow-2'
      }
      {
        ipAddress: '0.0.0.0/0'
        action: 'Deny'
        tag: 'Default'
        priority: 300
        name: 'Deny-All'
      }
    ]
  }
}

var keyVaultSecretUserRoleGuid = '4633458b-17de-408a-b874-0445c86b69e6' //Key Vault Secrets User  

resource keyVaultSecretUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webApp.name, keyVaultSecretUserRoleGuid)
  scope: keyvault
  properties: {
    principalId: webApp.outputs.systemAssignedPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretUserRoleGuid)
    principalType: 'ServicePrincipal'
  }
}

var storageAccountContributorRole = '17d1049b-9a84-46fb-8f53-869881c3d3ab' //Storage Account Contributor
resource storageAccountContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webApp.name, storageAccountContributorRole) 
  scope: storage
  properties: {
    principalId: webApp.outputs.systemAssignedPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageAccountContributorRole)
    principalType: 'ServicePrincipal'
  }
}

/*  resource secondStorageAccountContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webApp.name, storageAccountContributorRole, 'second') 
  scope: secondStorage
  properties: {
    principalId: webApp.outputs.systemAssignedPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageAccountContributorRole)
    principalType: 'ServicePrincipal'
  }
} */

/*var storageBlobDataContributorRole = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor

resource storageBlobDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webApp.name, storageBlobDataContributorRole) 
  scope: storage
  properties: {
    principalId: webApp.outputs.systemAssignedPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRole)
    principalType: 'ServicePrincipal'
  }
}

resource secondStorageBlobDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webApp.name, storageBlobDataContributorRole, 'second') 
  scope: secondStorage
  properties: {
    principalId: webApp.outputs.systemAssignedPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRole)
    principalType: 'ServicePrincipal'
  }
}*/

var acrPullRole = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webApp.name, acrPullRole) 
  scope: acr
  properties: {
    principalId: webApp.outputs.systemAssignedPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', acrPullRole)
    principalType: 'ServicePrincipal'
  }
}

//Write a secret on KV
resource apiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyvault
  tags: tags
  name: 'api-key'
  properties: {
    value: '78bbd136-1618-4a43-b9d5-9fcd66018ee4' //Random value
  }
}

// =========== //
// Outputs     //
// =========== //

@description('The name of the site.')
output name string = webApp.outputs.name

@description('The resource ID of the site.')
output resourceId string = webApp.outputs.resourceId

@description('The azure location of the site.')
output location string = webApp.outputs.location

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = webApp.outputs.systemAssignedPrincipalId

@description('Default hostname of the app.')
output defaultHostname string = webApp.outputs.defaultHostname

//@description ('output of log analystics workspace id')
//output logWsId string = logAnalyticsws.outputs.logAnalyticsWsId
