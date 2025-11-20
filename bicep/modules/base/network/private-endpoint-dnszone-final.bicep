//@description('Required. The Virtual Network (vNet) Name.')
//param name string

param resourcesNaming object
 
@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Virtual Network ID')
param virtualNetwork string

@description('Name of the subnet in the virtual network')
param snetBackend string
 
@description('Storage Account ID')
param said string
 
@description('Sql Server ID')
param sqlid string
 
@description('Redis ID')
param redisid string
 
@description('Container Registry ID')
param acrid string
 
@description('KV Server ID')
param kvid string

@description('SA PE Static IP')
param saPeIp string = '10.40.201.200'

@description('SQL PE Static IP')
param sqlPeIp string = '10.40.201.202'

@description('Redis PE Static IP')
param redisPeIp string = '10.40.201.203'

@description('KVA PE Static IP')
param kvPeIp string = '10.40.201.206'

@description('ACR PE Static IP')
param acrPeIp string = '10.40.201.204'

@description('ACR PE Static IP 2')
param acrPeIp1 string = '10.40.201.205'


/*@description('The name of the DNS record to be created.  The name is relative to the zone, not the FQDN.')
param sqlDnsName string = 'sql'

@description('The name of the DNS record to be created.  The name is relative to the zone, not the FQDN.')
param saDnsName string = 'sa'

@description('The name of the DNS record to be created.  The name is relative to the zone, not the FQDN.')
param redisDnsName string = 'redis'

@description('The name of the DNS record to be created.  The name is relative to the zone, not the FQDN.')
param kvDnsName string = 'kv'

@description('The name of the DNS record to be created.  The name is relative to the zone, not the FQDN.')
param acrDnsName string = 'acr'*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


resource saPrivDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

resource sqlPrivDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.database.windows.net'
  location: 'global'
}

resource redisPrivDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.redis.cache.windows.net'
  location: 'global'
}

resource acrPrivDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

resource kvPrivDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource saPrivDnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'priv-dns-multiple-blob-vnet-link'
  location: 'global'
  parent: saPrivDNS
  properties: {
    registrationEnabled: false
   virtualNetwork: {
       id: virtualNetwork
    }
  }
}


resource sqlPrivDnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'priv-dns-${resourcesNaming.sqlServer.name}-vnet-link'
  location: 'global'
  parent: sqlPrivDNS
  properties: {
    registrationEnabled: false
   virtualNetwork: {
       id: virtualNetwork
    }
  }
}

resource redisPrivDnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'priv-dns-${resourcesNaming.redisCache.name}-vnet-link'
  location: 'global'
  parent: redisPrivDNS
  properties: {
    registrationEnabled: false
   virtualNetwork: {
       id: virtualNetwork
    }
  }
}

resource acrPrivDnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'priv-dns-${resourcesNaming.containerRegistry.name}-vnet-link'
  location: 'global'
  parent: acrPrivDNS
  properties: {
    registrationEnabled: false
   virtualNetwork: {
       id: virtualNetwork
    }
  }
}

resource kvPrivDnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'priv-dns-${resourcesNaming.keyVault.name}-vnet-link'
  location: 'global'
  parent: kvPrivDNS
  properties: {
    registrationEnabled: false
   virtualNetwork: {
       id: virtualNetwork
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
resource saPeBlob 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.storageAccount.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations:  [
      {
        name: 'ipconfig1'
        properties: {
          groupId: 'blob'
          memberName: 'blob'
          privateIPAddress: saPeIp
        }
      }
    ]

    privateLinkServiceConnections: [
    {
      name: 'private-endpoint-peblob-conn'  // Note name looks like using ID.
      properties: {
        privateLinkServiceId: said
        groupIds:[
          'blob'
        ]
        privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
    ]
  }
}
 
resource sqlPe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.sqlServer.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations:  [
      {
        name: 'ipconfig1'
        properties: {
          groupId: 'sqlServer'
          memberName: 'sqlServer'
          privateIPAddress: sqlPeIp
        }
      }
    ]
    privateLinkServiceConnections: [
    {
      name: 'private-endpoint-pesql-conn'  // Note name looks like using ID.
      properties: {
        privateLinkServiceId: sqlid
        groupIds:[
          'sqlServer'
        ]
        privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
    ]
  }
}
 
 
resource redisPe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.redisCache.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations:  [
      {
        name: 'ipconfig1'
        properties: {
          groupId: 'redisCache'
          memberName: 'redisCache'
          privateIPAddress: redisPeIp
        }
      }
    ]    
    privateLinkServiceConnections: [
    {
      name: 'private-endpoint-peredis-conn'  // Note name looks like using ID.
      properties: {
        privateLinkServiceId: redisid
        groupIds:[
          'redisCache'
        ]
        privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
    ]
  }
}


resource acrPe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.containerRegistry.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations:  [
      {
        name: 'ipconfig1'
        properties: {
          groupId: 'registry'
          memberName: 'registry'
          privateIPAddress: acrPeIp
        }
      }
      {
        name: 'ipconfig2'
        properties: {
          groupId: 'registry'
          memberName: 'registry_data_eastus'
          privateIPAddress: acrPeIp1
        }
      }
    ]    
    privateLinkServiceConnections: [
    {
      name: 'private-endpoint-peacr-conn'  
      properties: {
        privateLinkServiceId: acrid
        groupIds:[
          'registry'
        ]
        privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
    ]
  }
}
 
 

resource kvPe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.keyVault.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations:  [
      {
        name: 'ipconfig1'
        properties: {
          groupId: 'vault'
          memberName: 'default'
          privateIPAddress: kvPeIp
        }
      }
    ]    
    privateLinkServiceConnections: [
    {
      name: 'private-endpoint-pekv-conn'  
      properties: {
        privateLinkServiceId: kvid
        groupIds:[
          'vault'
        ]
        privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
    ]
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


resource saPePrivDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'RavenPrivDnsZone'
  parent: saPeBlob
  properties: {
    privateDnsZoneConfigs: [
      {
        name: saPrivDNS.name
        properties: {
          privateDnsZoneId: saPrivDNS.id
        }
      }
    ]
  }
  dependsOn: [
  ]
}

resource sqlPePrivDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'RavenPrivDnsZone'
  parent: sqlPe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: sqlPrivDNS.name
        properties: {
          privateDnsZoneId: sqlPrivDNS.id
        }
      }
    ]
  }
  dependsOn: [
  ]
}

resource acrPePrivDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'RavenPrivDnsZone'
  parent: acrPe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: acrPrivDNS.name
        properties: {
          privateDnsZoneId: acrPrivDNS.id
        }
      }
    ]
  }
  dependsOn: [
  ]
}

resource kvPePrivDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'RavenPrivDnsZone'
  parent: kvPe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: kvPrivDNS.name
        properties: {
          privateDnsZoneId: kvPrivDNS.id
        }
      }
    ]
  }
  dependsOn: [
  ]
}

resource redisPePrivDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'RavenPrivDnsZone'
  parent: redisPe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: redisPrivDNS.name
        properties: {
          privateDnsZoneId: redisPrivDNS.id
        }
      }
    ]
  }
  dependsOn: [
  ]
}

