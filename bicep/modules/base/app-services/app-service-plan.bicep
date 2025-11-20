@description('Required. The name of the app service plan to deploy.')
@minLength(1)
@maxLength(40)
param name string

@description('Optional. Location for all resources.')
param location string

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional B1 is default. Defines the name, tier, size, family and capacity of the App Service Plan.')
@allowed([ 'B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1V3', 'P2V3', 'P3V3' ])
param sku string = 'B1'

@description('Optional, default is Linux. Kind of server OS.')
@allowed([
  'Windows'
  'Linux'
])
param serverOS string = 'Linux'


@description('Optional. The name of the diagnostic setting, if deployed.')
param diagnosticSettingsName string = '${name}-diagnosticSettings'

@description('Optional. Resource ID of the diagnostic log analytics workspace. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.')
param diagnosticWorkspaceId string = ''

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

// =========== //
// Variables   //
// =========== //

var aspKind =  (serverOS == 'Windows' ? '' : 'linux')

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
}]

// https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-configuration-set#example
var skuConfigurationMap = {
  B1: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  B2: {
    name: 'B2'
    tier: 'Basic'
    size: 'B2'
    family: 'B'
    capacity: 1
  }
  B3: {
    name: 'B3'
    tier: 'Basic'
    size: 'B3'
    family: 'B'
    capacity: 1
  }
  S1: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
  }
  S2: {
    name: 'S2'
    tier: 'Standard'
    size: 'S2'
    family: 'S'
    capacity: 1
  }
  S3: {
    name: 'S3'
    tier: 'Standard'
    size: 'S3'
    family: 'S'
    capacity: 1
  }
  P1V3: {
    name: 'P1V3'
    tier: 'PremiumV2'
    size: 'P1V3'
    family: 'Pv3'
    capacity: 1
  }
  P2V3: {
    name: 'P2V3'
    tier: 'PremiumV2'
    size: 'P2V3'
    family: 'Pv3'
    capacity: 1
  }
  P3V3: {
    name: 'P3V3'
    tier: 'PremiumV2'
    size: 'P3V3'
    family: 'Pv3'
    capacity: 1
  }
}

// =========== //
// Deployments //
// =========== //

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  kind: aspKind
  location: location
  tags: tags
  sku: skuConfigurationMap[sku]
  properties: {
    reserved: serverOS == 'Linux'
  }
}

resource appServicePlan_diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if ( !empty(diagnosticWorkspaceId) ) {
  name: diagnosticSettingsName
  properties: {
    storageAccountId: null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId:  null
    eventHubName: null
    metrics: diagnosticsMetrics
    logs: []
  }
  scope: appServicePlan
}

// =========== //
// Outputs     //
// =========== //
@description('The resource group the app service plan was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the app service plan.')
output name string = appServicePlan.name

@description('The resource ID of the app service plan.')
output resourceId string = appServicePlan.id

@description('The location the resource was deployed into.')
output location string = appServicePlan.location
