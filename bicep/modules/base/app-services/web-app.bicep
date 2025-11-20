@maxLength(60)
@description('Required. Name of the site.')
param name string

@description('Optional. Location for all Resources.')
param location string

@description('Required. Type of site to deploy.')
@allowed([
  'app' // normal web app
  'app,linux' // normal web app linux OS
  'app,linux,container' //web app for containers - linux
])
param kind string

@description('Required. The resource ID of the app service plan to use for the site.')
param serverFarmResourceId string

@description('Optional. Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests.')
param httpsOnly bool = true

@description('Optional. If client affinity is enabled.')
param clientAffinityEnabled bool = true

@description('Optional. The resource ID of the app service environment to use for this resource.')
param appServiceEnvironmentId string = ''

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. The resource ID of the assigned identity to be used to access a key vault with.')
param keyVaultAccessIdentityResourceId string = ''

// @description('Optional. Checks if Customer provided storage account is required.')
// param storageAccountRequired bool = false

@description('Optional. Azure Resource Manager ID of the Virtual network and subnet to be joined by Regional VNET Integration. This must be of the form /subscriptions/{subscriptionName}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}.')
param virtualNetworkSubnetId string = ''

@allowed(['windowsNet6', 'windowsNet7', 'windowsAspNet486', 'linuxJava17Se', 'linuxNet7', 'linuxNet6', 'linuxNode18', 'dockerLinuxNet7'])
@description('Mandatory. Predefined set of config settings.')
param siteConfigSelection string 

@description('Mandatory. Docker image name for linuxFxVersion.')
param dockerImageName string

// @description('Optional. Required if app of kind functionapp. Resource ID of the storage account to manage triggers and logging function executions.')
// param storageAccountId string = ''

@description('Optional. Resource ID of the app insight to leverage for this resource.')
param appInsightId string = ''

@description('Optional. The app settings-value pairs except for AzureWebJobsStorage, AzureWebJobsDashboard, APPINSIGHTS_INSTRUMENTATIONKEY and APPLICATIONINSIGHTS_CONNECTION_STRING.')
param appSettingsKeyValuePairs object = {}

@description('Optional. The connection strings pairs')
param appConnectionStringsKeyValuePairs object = {}

// Tags
@description('Optional. Tags of the resource.')
param tags object = {}

// Diagnostic Settings

@description('Optional. Resource ID of log analytics workspace.')
param diagnosticWorkspaceId string = ''


@description('Optional. The name of logs that will be streamed. "allLogs" includes all possible logs for the resource.')
@allowed([
  'allLogs'
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
])
param diagnosticLogCategoriesToEnable array = [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. The name of the diagnostic setting, if deployed.')
param diagnosticSettingsName string = '${name}-diagnosticSettings'


// @description('Optional. Size of the function container.')
// param containerSize int = -1

@description('Optional. Unique identifier that verifies the custom domains assigned to the app. Customer will add this ID to a txt record for verification.')
param customDomainVerificationId string = ''

@description('Optional. Setting this value to false disables the app (takes the app offline).')
param enabled bool = true

@description('Optional. Hostname SSL states are used to manage the SSL bindings for app\'s hostnames.')
param hostNameSslStates array = []

@description('Optional, default is false. If true, then a private endpoint must be assigned to the web app')
param hasPrivateLink bool

//@description('Required. ID for Azure Front Door used in IP Restrictions.')
//param frontDoorId string

@description('Optional. List of IP address restrictions.')
param ipSecurityRestrictions array = [
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


// =========== //
// Variables   //
// =========== //
var diagnosticsLogsSpecified = [for category in filter(diagnosticLogCategoriesToEnable, item => item != 'allLogs'): {
  category: category
  enabled: true
}]

var diagnosticsLogs = contains(diagnosticLogCategoriesToEnable, 'allLogs') ? [
  {
    categoryGroup: 'allLogs'
    enabled: true
  }
] : diagnosticsLogsSpecified

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
}]

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null

var webapp_dns_name = '.azurewebsites.net'

// ============ //
// Dependencies //
// ============ //

var siteConfigConfigurationMap  = {
  windowsNet6 : {    
    metadata :[
      {
        name:'CURRENT_STACK'
        value:'dotnet'
      }
    ]
    netFrameworkVersion: 'v6.0'
    use32BitWorkerProcess: false
    acrUseManagedIdentityCreds: true  //ToDo Flag to use Managed Identity Creds for ACR pull 
  }
  windowsNet7 : {
    metadata :[
      {
        name:'CURRENT_STACK'
        value:'dotnet'
      }
    ]
    netFrameworkVersion: 'v7.0'
    use32BitWorkerProcess: false
    acrUseManagedIdentityCreds: true  //ToDo Flag to use Managed Identity Creds for ACR pull     
  }
  windowsAspNet486 : {
    metadata :[
      {
        name:'CURRENT_STACK'
        value:'dotnet'
      }
    ]
    netFrameworkVersion: 'v4.0'
    use32BitWorkerProcess: false    
  }
  linuxJava17Se: {
    linuxFxVersion: 'JAVA|17-java17'
    use32BitWorkerProcess: false    
  }
  linuxNet7: {
    linuxFxVersion: 'DOTNETCORE|7.0'
    use32BitWorkerProcess: false
    acrUseManagedIdentityCreds: true  //Use Managed Identity Creds for ACR pull
    ipSecurityRestrictionsDefaultAction: 'Deny'
    ipSecurityRestrictions: ipSecurityRestrictions   
  }
  linuxNet6: {
    linuxFxVersion: 'DOTNETCORE|6.0'
    use32BitWorkerProcess: false
    acrUseManagedIdentityCreds: true  //Use Managed Identity Creds for ACR pull
    ipSecurityRestrictionsDefaultAction: 'Deny'
    ipSecurityRestrictions: ipSecurityRestrictions      
  }
  linuxNode18: {
    linuxFxVersion: 'NODE|18-lts'
    use32BitWorkerProcess: false    
  }
  dockerLinuxNet7: {
    linuxFxVersion: dockerImageName
    use32BitWorkerProcess: false
    acrUseManagedIdentityCreds: true //Use Managed Identity Creds for ACR pull
    ipSecurityRestrictionsDefaultAction: 'Deny'
    ipSecurityRestrictions: ipSecurityRestrictions
  }
}

resource app 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  kind: kind
  tags: tags
  identity: identity
  properties: {
    serverFarmId: serverFarmResourceId
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: httpsOnly
    hostingEnvironmentProfile: !empty(appServiceEnvironmentId) ? {
      id: appServiceEnvironmentId
    } : null
    storageAccountRequired: false
    keyVaultReferenceIdentity: !empty(keyVaultAccessIdentityResourceId) ? keyVaultAccessIdentityResourceId : null
    virtualNetworkSubnetId: !empty(virtualNetworkSubnetId) ? virtualNetworkSubnetId : any(null)
    vnetRouteAllEnabled: !empty(virtualNetworkSubnetId) ? true : false
    siteConfig: siteConfigConfigurationMap[siteConfigSelection]
    clientCertEnabled: false
    clientCertExclusionPaths: null
    clientCertMode: 'Optional'
    cloningInfo: null
    containerSize:  null
    customDomainVerificationId: !empty(customDomainVerificationId) ? customDomainVerificationId : null
    enabled: enabled
    hostNameSslStates: hostNameSslStates
    hyperV: false
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled' // Ensures public network access remains enabled
    ipSecurityRestrictionsDefaultAction: 'Deny'
    ipSecurityRestrictions: ipSecurityRestrictions
  }
}

resource webAppHostBinding 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = if (hasPrivateLink == true) {
  parent: app
  name: '${app.name}${webapp_dns_name}'
  properties: {
    siteName: app.name
    hostNameType: 'Verified'
  }
}

module app_appsettings 'web-app.appsettings.bicep' = { 
  name: 'Site-Config-AppSettings-${uniqueString(deployment().name, location)}'
  params: {
    appName: app.name
    kind: kind
    appInsightId: appInsightId
    appSettingsKeyValuePairs: appSettingsKeyValuePairs
  }
}

module app_connectionStrings 'web-app.connectionstrings.bicep' = { 
  name: 'Site-Config-ConnectionStrings-${uniqueString(deployment().name, location)}'
  params: {
    appName: app.name
    appConnectionStringsKeyValuePairs: appConnectionStringsKeyValuePairs
  }
}

resource slot_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if ( !empty(diagnosticWorkspaceId)) {
  name: diagnosticSettingsName
  properties: {
    storageAccountId: null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId:  null
    eventHubName: null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: app
}


// =========== //
// Outputs     //
// =========== //

@description('The name of the site.')
output name string = app.name

@description('The resource ID of the site.')
output resourceId string = app.id

@description('The azure location of the site.')
output location string = app.location

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(app.identity, 'principalId') ? app.identity.principalId : ''

@description('Default hostname of the app.')
output defaultHostname string = app.properties.defaultHostName
