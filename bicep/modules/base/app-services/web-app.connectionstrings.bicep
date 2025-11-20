// ================ //
// Parameters       //
// ================ //
@description('Conditional. The name of the parent site resource. Required if the template is used in a standalone deployment.')
param appName string

@description('The connection strings used in the application')
param appConnectionStringsKeyValuePairs object = {}

// =========== //
// Variables   //
// =========== //


// =========== //
// Existing resources //
// =========== //
resource app 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appName
}

resource connectionStrings 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'connectionstrings'
  kind: 'string'
  parent: app
  properties: appConnectionStringsKeyValuePairs
}

// =========== //
// Outputs     //
// =========== //
@description('The name of the site config.')
output name string = connectionStrings.name

@description('The resource ID of the site config.')
output resourceId string = connectionStrings.id

@description('The resource group the site config was deployed into.')
output resourceGroupName string = resourceGroup().name
