param networkResourceGroupName string
param location string
param tags object = {}

resource networkRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkResourceGroupName
  location: location
  tags: tags
}