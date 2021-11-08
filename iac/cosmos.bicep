param name string
param location string
param dbName string
param containerName string

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: name
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
  }

  resource db 'sqlDatabases' = {
    name: dbName
    properties: {
      resource: {
        id: dbName
      }
      options: {
        throughput: 400
      }
    }

    resource container 'containers' = {
      name: containerName
      properties: {
        resource: {
          id: containerName
          partitionKey: {
            kind: 'Hash'
            paths: [
              '/id'
            ]
          }
        }
      }
    }
  }
}

output endpoint string = cosmos.properties.documentEndpoint
output primaryKey string = cosmos.listKeys().primaryMasterKey
