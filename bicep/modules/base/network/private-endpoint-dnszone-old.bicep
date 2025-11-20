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

@description('Container Apps Environment ID')
param caeId string

@description('SA PE Static IP')
param saPeIp string = '10.40.202.200'

@description('SQL PE Static IP')
param sqlPeIp string = '10.40.202.202'

@description('Redis PE Static IP')
param redisPeIp string = '10.40.202.203'

@description('KVA PE Static IP')
param kvPeIp string = '10.40.202.206'

@description('ACR PE Static IP')
param acrPeIp string = '10.40.202.204'

@description('ACR PE Static IP 2')
param acrPeIp1 string = '10.40.202.205'

@description('Container Apps Environment PE Static IP')
param caePeIp string = '10.40.202.207'

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Private DNS Zones
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

resource caePrivDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecontainerapps.io'
  location: 'global'
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VNet Links
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
  dependsOn: [
    saPrivDNS
  ]
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
  dependsOn: [
    sqlPrivDNS
  ]
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
  dependsOn: [
    redisPrivDNS
  ]
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
  dependsOn: [
    acrPrivDNS
  ]
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
  dependsOn: [
    kvPrivDNS
  ]
}


resource caePrivDnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'priv-dns-${resourcesNaming.containerAppEnv.name}-vnet-link'
  location: 'global'
  parent: caePrivDNS
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork
    }
  }
  dependsOn: [
    caePrivDNS
  ]
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Private Endpoints
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource saPeBlob 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.storageAccount.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations: [
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
        name: 'private-endpoint-peblob-conn'
        properties: {
          privateLinkServiceId: said
          groupIds: [
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
  dependsOn: [
    saPrivDnsVnetLink
  ]
}

resource sqlPe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.sqlServer.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations: [
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
        name: 'private-endpoint-pesql-conn'
        properties: {
          privateLinkServiceId: sqlid
          groupIds: [
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
  dependsOn: [
    sqlPrivDnsVnetLink
  ]
}

resource redisPe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.redisCache.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations: [
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
        name: 'private-endpoint-peredis-conn'
        properties: {
          privateLinkServiceId: redisid
          groupIds: [
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
  dependsOn: [
    redisPrivDnsVnetLink
  ]
}

resource acrPe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.containerRegistry.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations: [
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
          memberName: 'registry_data_uksouth'
          privateIPAddress: acrPeIp1
        }
      }
    ]    
    privateLinkServiceConnections: [
      {
        name: 'private-endpoint-peacr-conn'  
        properties: {
          privateLinkServiceId: acrid
          groupIds: [
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
  dependsOn: [
    acrPrivDnsVnetLink
  ]
}

resource kvPe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.keyVault.name}'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations: [
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
          groupIds: [
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
  dependsOn: [
    kvPrivDnsVnetLink
  ]
}

resource caePe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'privateEndpoint-${resourcesNaming.containerAppEnv.name}'
  location: location
  properties: {
    subnet: {
      id: snetBackend
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          groupId: 'environment'
          memberName: 'managedEnvironment'
          privateIPAddress: caePeIp
        }
      }
    ]
    privateLinkServiceConnections: [
      {
        name: 'private-endpoint-pecae-conn'
        properties: {
          privateLinkServiceId: caeId
          groupIds: [
            'environment'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
  }
  dependsOn: [
    caePrivDnsVnetLink
  ]
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DNS Zone Groups (must wait for both DNS zone + PE)
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
    saPeBlob
    saPrivDNS
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
    sqlPe
    sqlPrivDNS
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
    acrPe
    acrPrivDNS
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
    kvPe
    kvPrivDNS
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
    redisPe
    redisPrivDNS
  ]
}

resource caePePrivDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'RavenPrivDnsZone'
  parent: caePe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: caePrivDNS.name
        properties: {
          privateDnsZoneId: caePrivDNS.id
        }
      }
    ]
  }
  dependsOn: [
    caePe
    caePrivDNS
  ]
}
