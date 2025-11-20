param resourcesNaming object
param location string 
param tags object

@description('Conditional. The administrator username for the server. Required if no `administrators` object for AAD authentication is provided.')
param administratorLogin string = ''

@description('Conditional. The administrator login password. Required if no `administrators` object for AAD authentication is provided.')
@secure()
param administratorLoginPassword string = ''

@description('Conditional. The Azure Active Directory (AAD) administrator authentication. Required if no `administratorLogin` & `administratorLoginPassword` is provided.')
param administrators object = {}

// database related params
@description('Required. The name of the Sql database.')
param databaseName string

@description('Optional, default is S0. The SKU of the database ')
@allowed([
  'S0'
  'S1'
  'S2'
  'S3'
  'S4'
  'S6'
  'S7'
  'S9'
  'S12'
])
param databaseSkuName string = 'S0'

@description('Whether to enable Transparent Data Encryption -defaults to \'true\'')
param enableTransparentDataEncryption bool = true

// Key Vault
@description('The resource ID of the key vault to store the license key for the backend processor service.')
param keyVaultName string

@description('The name of the secret or The SQL administrator login user.')
param sqlAdministratorLoginSecretName string

@secure()
@description('The SQL administrator login user.')
param sqlAdministratorLoginSecretValue string

@description('The name of the secret or The SQL administrator login password.')
param sqlAdministratorLoginPasswordSecretName string

@secure()
@description('The SQL administrator login password.')
param sqlAdministratorLoginPasswordSecretValue string


// ------------------
// VARIABLES
// ------------------


module sqlServer 'modules/base/databases/sql.bicep' = {
  name: 'sqlserver-${uniqueString(resourceGroup().id)}'
  params: {
   name: resourcesNaming.sqlServer.name
     databaseName: databaseName
     databaseSkuName: databaseSkuName
     enableTransparentDataEncryption: enableTransparentDataEncryption
      hasPrivateLinks: false
        publicNetworkAccess: 'Enabled'
        administratorLogin: administratorLogin
        administratorLoginPassword: administratorLoginPassword
         administrators: administrators
    location: location
    tags: tags
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource sqlAdministratorLogin 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  tags: tags
  name: sqlAdministratorLoginSecretName
  properties: {
    value: sqlAdministratorLoginSecretValue
  }
}

resource sqlAdministratorLoginPassword 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  tags: tags
  name: sqlAdministratorLoginPasswordSecretName
  properties: {
    value: sqlAdministratorLoginPasswordSecretValue
  }
}

@description('The name of the deployed SQL server.')
output sqlServerName string = sqlServer.outputs.sqlServerName

@description('The name of the created DB name.')
output databaseName string = databaseName

@description('The resource ID of the deployed SQL server.')
output sqlServerId string = sqlServer.outputs.sqlServerId

@description('The fully Qualified Domain Name of the server.')
output fullyQualifiedDomainName string = sqlServer.outputs.fullyQualifiedDomainName


