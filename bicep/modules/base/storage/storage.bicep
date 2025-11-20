@description('name must be max 24 chars, globally unique, all lowercase letters or numbers with no spaces.')
param name string
param location string
param tags object

@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
@description('Optional. Type of Storage Account to create.')
param kind string = 'StorageV2'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Optional. Storage Account Sku Name.')
param sku string = 'Standard_LRS'

@allowed([
  'Hot'
  'Cool'
])
@description('Optional. Storage Account Access Tier.')
param accessTier string = 'Hot'

@description('Optional. Allows HTTPS traffic only to storage service if sets to true.')
param supportsHttpsTrafficOnly bool = true

@description('the firewall ip address to allow in - whitelist')
param whitelistpublicip string = '8.8.8.8'

param networkAcls object = {}

// Variables
var maxNameLength = 24
var storageNameValid = toLower(replace(name, '-', ''))
var uniqueStorageName = length(storageNameValid) > maxNameLength ? substring(storageNameValid, 0, maxNameLength) : storageNameValid

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {  
  name: uniqueStorageName
  location: location  
  kind: kind
  sku: {
    name: sku
  }
  tags: union(tags, {
    displayName: uniqueStorageName
  })  
properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: [
        {
          value: whitelistpublicip
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
  }
  
  
}

output id string = storage.id
output name string = storage.name
output apiVersion string = storage.apiVersion
// output primaryKey string = listKeys(storage.id, storage.apiVersion).keys[0].value
// output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value}'
