targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

// Parameters
@description('Required. Azure location to which the resources are to be deployed -defaults to the location of the resource group')
param location string 

//param mainResourceGroupName string

@description('Name of the networking resource group (create if not exists).')
param networkResourceGroupName string

@description('Required. A short name for the workload being deployed')
param workloadName string

@description('Required. A short name for the organization name deploying resources')
param organizationName string

@description('Required. The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'v1'
])
param environment string

@description('Optional. A numeric suffix (e.g. "001") to be appended on the naming generated for the resources. Defaults to empty.')
param numericSuffix string = ''

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Optional. Create Redis resource.')
param createRedisResource bool = false

@description('Azure Active Directory only Authentication enabled.')
param azureADOnlyAuthentication bool = false

@description('Azure AD Login name of the server administrator (AD User or Group).')
param azureADSqlAdminLoginName string

@description('Azure AD SID (object ID) of the server administrator.')
param azureADSqlAdminSid string

@description('Optional. Create Azure Static Web App resource.')
param createStaticWebApp bool = true

@allowed([
  'Application'
  'Group'
  'User'
])
@description('Azure AD Principal Type of the sever administrator.')
param azureADSqlAdminPrincipalType string = 'User'

@description('Optional. The name of the secret or The SQL administrator login user.')
param sqlAdministratorLoginSecretName string = 'SQL-SA-User'

@description('Optional. The name of the secret or The SQL administrator login password.')
param sqlAdministratorLoginPasswordSecretName string = 'SQL-SA-Password'

@description('Conditional. The administrator username for the server. Required if no `administrators` object for AAD authentication is provided.')
param sqlAdministratorLogin string

@description('Conditional. The administrator login password. Required if no `administrators` object for AAD authentication is provided.')
@secure()
param sqlAdministratorLoginPassword string

@description('Required. The name of the Sql database.')
param databaseName string

param acrName string

@description('Optional. The name of an existing log analytics workspace, if not provided a new log analytics workspace will be created.')
param logAnalyticsWSName string = ''

@description('Conditional. The name of the resource group of the log analytics workspace. Required when logAnalyticsWSName is provided')
param logAnalyticsWSRGName string = ''

// ------------------
// VARIABLES
// ------------------

// var resourceSuffix = <resource>-<location>-<organization>-<workload>-<environment>
// eg: kv-uks-mc-DealMechanic-dev

var defaultSuffixes = [
  '**location**'
  organizationName
  workloadName
  environment
]
var namingSuffixes = empty(numericSuffix) ? defaultSuffixes : concat(defaultSuffixes, [
    numericSuffix
  ])




module naming 'modules/base/naming.module.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: 'namingModule-Deployment'
  params: {
    location: location
    suffix: namingSuffixes
    uniqueLength: 6
  }
}

var resourcesNaming = naming.outputs.names

// ------------------
// RESOURCES
// ------------------

module acr 'modules/base/container-registry/acr.bicep' = {
  name: 'acr-${uniqueString(resourceGroup().id)}'
  params: {
    name: resourcesNaming.containerRegistry.name
    acrSku: 'Premium'
    adminUserEnabled: false
    location: location
    tags: tags
  }
}

module managedidentiydata 'modules/base/container-apps/managedidentity.bicep' = {
  name: 'ident-${uniqueString(resourceGroup().id)}'
  params: {
    name: '${resourcesNaming.userAssignedManagedIdentity.name}'  
    acrName: acr.outputs.name
    keyVaultname: keyVault.outputs.keyVaultName
    location: location
    tags: tags
  }
}


module keyVault 'modules/base/keyvault.bicep' = {
  name: 'keyVault-${uniqueString(resourceGroup().id)}'
  params: {
    name: resourcesNaming.keyVault.name
    enableRbacAuthorization: true
    hasPrivateEndpoint: false
    location: location
    tags: tags
  }
}

module storageAccount 'storage.module.bicep' = {
  name: 'storageAccount-${uniqueString(resourceGroup().id)}'
  params: {
    resourcesNaming: resourcesNaming
    location: location
    tags: tags
    containers: [
      { name: 'secure-downloads', publicAccess: 'None' }
      { name: 'secure-downloads1', publicAccess: 'None' }
    ]
  }
}

module sql 'sql.database.module.bicep' = {
  name: 'sql-${uniqueString(resourceGroup().id)}'
  params: {
    resourcesNaming: resourcesNaming
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    sqlAdministratorLoginSecretName: sqlAdministratorLoginSecretName
    sqlAdministratorLoginSecretValue: sqlAdministratorLogin
    sqlAdministratorLoginPasswordSecretName: sqlAdministratorLoginPasswordSecretName
    sqlAdministratorLoginPasswordSecretValue: sqlAdministratorLoginPassword
    keyVaultName: keyVault.outputs.keyVaultName
    administrators: {
      azureADOnlyAuthentication: azureADOnlyAuthentication
      principalType: azureADSqlAdminPrincipalType
      login: azureADSqlAdminLoginName
      sid: azureADSqlAdminSid
      tenantId: subscription().tenantId
    }
    databaseName: '${resourcesNaming.sqlServer.name}-db-dealmechanic'
    databaseSkuName: 'S0'
    enableTransparentDataEncryption: true
    location: location
    tags: tags
  }
}

//Create Redis resource
module redis 'modules/base/databases/redis.bicep' = if (createRedisResource) {
  name: 'redis-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    keyVaultName: keyVault.outputs.keyVaultName
    redisConnectionSecretName: 'Redis-Connection'
    name: resourcesNaming.redisCache.name
    capacity: 0
    shardCount: 1
    skuName: 'Basic'
    tags: tags
  }
}

module vnetdata 'modules/base/network/virtual-network.bicep' = {
  name: 'vnet-${uniqueString(resourceGroup().id)}'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    name: resourcesNaming.virtualNetwork.name
    addressPrefixes: ['10.40.202.0/24']
    location: location
    tags: tags
    subnets: [
      {
        name: 'subnet-Frontend'
        addressPrefix: '10.40.202.0/27'
        networkSecurityGroupResourceId: nsg.outputs.networkSecurityGroup
        delegations: [
      {
        name: 'appDel'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
     ]
      }
      {
        name: 'subnet-Backend'
        addressPrefix: '10.40.202.64/26'
          delegations: [
        {
          name: 'appDel'
          properties: {
            serviceName: 'Microsoft.App/environments'
          }
        }
      ]
    }
          {
        name: 'subnet-PrivateEndpoints'
        addressPrefix: '10.40.202.192/26'
    }
  ]
}
}

module nsg 'modules/base/network/nsg.bicep' = {
  name: 'nsg-${uniqueString(resourceGroup().id)}'
  scope:resourceGroup(networkResourceGroupName)
  params: {
    name: resourcesNaming.networkSecurityGroup.name
    location: location
    tags: tags
    }
}

module pe 'modules/base/network/private-endpoint-dnszone-old.bicep' = {
  name: 'peModule-Deployment'
  scope:resourceGroup(networkResourceGroupName)
  params: {
    resourcesNaming: resourcesNaming
    location: location
    snetBackend: vnetdata.outputs.subnetResourceIds[2]
    virtualNetwork: vnetdata.outputs.resourceId
    said: storageAccount.outputs.id
    sqlid: sql.outputs.sqlServerId
    redisid: redis.outputs.resourceId
    acrid: acr.outputs.Id
    kvid: keyVault.outputs.keyVaultId
    caeId: containerappenv.outputs.containerAppEnvironmentId
  }
}


module containerappenv 'modules/base/container-apps/containerappenv.bicep' = {
  name: 'cae-${uniqueString(resourceGroup().id)}'
  params: {
    name: '${resourcesNaming.containerAppsEnvironment.name}'
    location: location
    infraSubnetId: vnetdata.outputs.subnetResourceIds[1]
    internalVirtualIp: true
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
    ]
    tags: tags
  }
}


module canats 'modules/base/container-apps/containerapp.bicep' = {
  name: 'ca-nats-${uniqueString(resourceGroup().id)}'
  params: {
    containerAppName: '${resourcesNaming.containerApps.name}-nats'
    location: location
    tags: tags
    environmentResourceId: containerappenv.outputs.containerAppEnvironmentId

    containers: [
      {
        name: 'helloworld'
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
      }
    ]
    managedIdentities: {
  userAssignedResourceIds: [
    managedidentiydata.outputs.id
  ]
}

  }
}


module cagateway 'modules/base/container-apps/containerapp.bicep' = {
  name: 'ca-gateway-${uniqueString(resourceGroup().id)}'
  params: {
    containerAppName: '${resourcesNaming.containerApps.name}-gateway'
    location: location
    tags: tags
    environmentResourceId: containerappenv.outputs.containerAppEnvironmentId

    containers: [
      {
        name: 'helloworld'
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
      }
    ]
    managedIdentities: {
  userAssignedResourceIds: [
    managedidentiydata.outputs.id
  ]
}
  }
}

module cachat 'modules/base/container-apps/containerapp.bicep' = {
  name: 'ca-chat-${uniqueString(resourceGroup().id)}'
  params: {
    containerAppName: '${resourcesNaming.containerApps.name}-chat'
    location: location
    tags: tags
    environmentResourceId: containerappenv.outputs.containerAppEnvironmentId

    containers: [
      {
        name: 'helloworld'
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
      }
    ]
    managedIdentities: {
  userAssignedResourceIds: [
    managedidentiydata.outputs.id
  ]
}
  }
}

module cahist 'modules/base/container-apps/containerapp.bicep' = {
  name: 'ca-hist-${uniqueString(resourceGroup().id)}'
  params: {
    containerAppName: '${resourcesNaming.containerApps.name}-chathist'
    location: location
    tags: tags
    environmentResourceId: containerappenv.outputs.containerAppEnvironmentId

    containers: [
      {
        name: 'helloworld'
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
      }
    ]
    managedIdentities: {
  userAssignedResourceIds: [
    managedidentiydata.outputs.id
  ]
}
  }
}


module cafiles 'modules/base/container-apps/containerapp.bicep' = {
  name: 'ca-files-${uniqueString(resourceGroup().id)}'
  params: {
    containerAppName: '${resourcesNaming.containerApps.name}-files'
    location: location
    tags: tags
    environmentResourceId: containerappenv.outputs.containerAppEnvironmentId

    containers: [
      {
        name: 'helloworld'
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
      }
    ]
    managedIdentities: {
  userAssignedResourceIds: [
    managedidentiydata.outputs.id
  ]
}
  }
}


module cawebnettools 'modules/base/container-apps/containerapp.bicep' = {
  name: 'ca-webntools-${uniqueString(resourceGroup().id)}'
  params: {
    containerAppName: '${resourcesNaming.containerApps.name}-webntools'
    location: location
    tags: tags
    environmentResourceId: containerappenv.outputs.containerAppEnvironmentId

    containers: [
      {
        name: 'webntools'
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
      }
    ]
    managedIdentities: {
  userAssignedResourceIds: [
    managedidentiydata.outputs.id
  ]
}
  }
}


module staticWebApp 'modules/base/app-services/static-web-app.bicep' = {
  name: 'swa-${uniqueString(resourceGroup().id)}'
  params: {
    name: resourcesNaming.staticWebApp.name
    location: 'westeurope'
    tags: tags
    sku: 'Standard'
    enableManagedIdentity: true
  }
}
