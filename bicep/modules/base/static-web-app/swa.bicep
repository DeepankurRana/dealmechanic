

@description('Required. Name of the static web app.')
param name string

@allowed([ 'centralus', 'eastus2', 'eastasia', 'westeurope', 'westus2' ])
param location string

@allowed([ 'Free', 'Standard' ])
param sku string = 'Standard'
@allowed([ '','SystemAssigned', 'UserAssigned' ])
@description('Type of managed service identity. SystemAssigned, UserAssigned. https://docs.microsoft.com/en-us/azure/templates/microsoft.web/staticsites?tabs=bicep#managedserviceidentity')
param identityType string = ''

@description('The list of user assigned identities associated with the resource.')
param userAssignedIdentities object = {}

@secure()
@description('Configuration for the static site.')
param appSettings object = {}


@description('Optional. Tags of the resource.')
param tags object = {}


resource staticSite 'Microsoft.Web/staticSites@2022-09-01' = {
    name: name
    location: location
    tags: tags
    identity: empty(identityType) ? null: {
        type: identityType
        userAssignedIdentities: empty(userAssignedIdentities) ? null : userAssignedIdentities
      }
    properties: {}
    sku: {
        name: sku
        size: sku
        tier: sku
    }
}

resource staticSiteAppsettings 'Microsoft.Web/staticSites/config@2021-02-01' = if ( !empty(appSettings)) {
    parent: staticSite
    name: 'appsettings'
    kind: 'config'
    properties: appSettings
  }
  
output defaultHostName string = staticSite.properties.defaultHostname // eg epic-shark-0db05de03.azurestaticapps.net
output siteName string = staticSite.name
output siteResourceId string = staticSite.id
output siteSystemAssignedIdentityId string = !empty(identityType) ? ((staticSite.identity.type == 'SystemAssigned') ? staticSite.identity.principalId : '') : ''
