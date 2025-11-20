//nsg.bicep

@description('The Name of the NSG resource.')
param name string

@description('Optional. Location for all resources.')
param location string

@description('Resource tags that we might need to add to all resources (i.e. Environment, Cost center, application name etc)')
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow_RDP_Access_to_Host'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '10.100.100.1'
          destinationAddressPrefix: '10.101.101.101/32'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_SSH_Access_to_Host'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '10.100.100.0/26'
          destinationAddressPrefix: '10.101.101.101/32'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

output networkSecurityGroup string = nsg.id
