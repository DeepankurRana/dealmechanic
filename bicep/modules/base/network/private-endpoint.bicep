//@description('Required. The Virtual Network (vNet) Name.')
//param name string
 
@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('ID of the virtual network to link DNS zones to')
param vnetId string

@description('Name prefix for Private DNS Zones')
param dnsZonePrefix string = ''
 
@description('Name of the subnet in the virtual network')
param snetBackend string
 
@description('Storage Account ID')
param said string

//@description('Storage Account ID')
//param sastaticid string
 
@description('Sql Server ID')
param sqlid string
 
@description('Sql Server ID')
param redisid string
 
@description('Sql Server ID')
param acrid string
 
@description('KV Server ID')
param kvid string

@description('SA PE Static IP')
param sapeblobip string = '10.40.202.200'

@description('SQL PE Static IP')
param  sqlpeip string = '10.40.202.202'

@description('Redis PE Static IP')
param redispeip string = '10.40.202.203'

@description('ACR PE Static IP')
param acrpeip string = '10.40.202.204'

@description('ACR PE Static IP')
param acrPeIp1 string = '10.40.202.205'

@description('KVA PE Static IP')
param kvpeip string = '10.40.202.206'
 
resource sapeblob 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'private-endpoint-pe-blob'
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
          privateIPAddress: sapeblobip
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

 
resource sqlpe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'private-endpoint-pe-sql'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations:  [
      {
        name: 'ipconfig2'
        properties: {
          groupId: 'sqlServer'
          memberName: 'sqlServer'
          privateIPAddress: sqlpeip
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
 
 
resource redispe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'private-endpoint-pe-redis'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
     ipConfigurations:  [
      {
        name: 'ipconfig3'
        properties: {
          groupId: 'redisCache'
          memberName: 'redisCache'
          privateIPAddress: redispeip
        }
      }
    ]
    privateLinkServiceConnections: [
    {
      name: 'private-endpoint-pesql-conn'  // Note name looks like using ID.
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
 
 
resource acrpe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'private-endpoint-pe-acr'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
     ipConfigurations:  [
      {
        name: 'ipconfig4'
        properties: {
          groupId: 'registry'
          memberName: 'registry'
          privateIPAddress: acrpeip
        }
      }
     {
        name: 'ipconfig7'
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
 
 
resource kvpe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'private-endpoint-pe-kv'
  location: location
  properties:{
    subnet: {
      id: snetBackend
    }
    ipConfigurations:  [
      {
        name: 'ipconfig5'
        properties: {
          groupId: 'vault'
          memberName: 'default'
          privateIPAddress: kvpeip
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

///////////////////////////////////////////////DNS Zones ///////////////////////////////////////////////


resource saDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

resource saDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${saDnsZone.name}/${dnsZonePrefix}-sa-vnetlink'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
  dependsOn: [
    saDnsZone
  ]
}

resource saDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${sapeblob.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: saDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    sapeblob
    saDnsZone
  ]
}
