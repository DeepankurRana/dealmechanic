
param resourcesNaming object
param location string 
param tags object
param containers array = []


module storage 'modules/base/storage/storage.bicep' = {
  name: 'storage-${uniqueString(resourceGroup().id)}'
  params: {
    name: resourcesNaming.storageAccount.name
    sku: 'Standard_LRS'
    location: location
    tags: tags
  }
}

module storageBlobSvc 'modules/base/storage/storage.blobsvc.bicep' = {
  name: 'storageBlobSvc-${uniqueString(resourceGroup().id)}'
  params: {
    name: 'default'
    storageAccountName: storage.outputs.name
    containers: containers
  }
}


output id string = storage.outputs.id
output name string = storage.outputs.name
output blobServicesName string = storageBlobSvc.outputs.name
// output containerName string = storageBlobContainer.outputs.name

