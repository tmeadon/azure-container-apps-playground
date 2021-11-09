param storageName string
param queueName string
param location string

resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'

  resource queueServices 'queueServices' = {
    name: 'default'

    resource queue 'queues' = {
      name: queueName
    }
  }
}

output storageConnection string = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value}'
