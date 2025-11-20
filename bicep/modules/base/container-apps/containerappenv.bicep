@description('Required. Prefix of containerAppEnv Resource Name. This param is ignored when name is provided.')
param prefix string = 'cae'

@description('Optional. The name of the containerAppEnv resource.')
param name string = '${prefix}${uniqueString(resourceGroup().id)}'

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Specifies workload profiles configured for the Managed Environment.')
param workloadProfiles array = []

param zoneRedundant bool = false


param infraSubnetId string = ''


param tags object = {}

@description('Sets the environment to only have a internal load balancer')
param internalVirtualIp bool = false

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-02-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: infraSubnetId
      internal: internalVirtualIp
    }
    workloadProfiles: workloadProfiles
    zoneRedundant: zoneRedundant
  }
}


output containerAppEnvironmentName string = containerAppEnv.name
output containerAppEnvironmentId string = containerAppEnv.id
