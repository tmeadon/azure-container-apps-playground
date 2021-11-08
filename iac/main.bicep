targetScope = 'subscription'

param baseName string = 'tmtestaca'
param location string = 'northeurope'
param acrName string = baseName
param acrResourceGroupName string = baseName
param frontendImageName string
param frontendImageVersion string
param backendImageName string
param backendImageVersion string

var cosmosDbName = 'db'
var cosmosContainerName = 'names'

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: baseName
  location: location
}

module cosmos 'cosmos.bicep' = {
  scope: rg
  name: 'cosmos'
  params: {
    containerName: cosmosContainerName
    dbName: cosmosDbName
    location: location
    name: '${baseName}-${uniqueString(rg.id)}'
  }
}

module environment 'environment.bicep' = {
  scope: rg
  name: 'environment'
  params: {
    name: baseName
  }
}

module frontend 'container_http.bicep' = {
  scope: rg
  name: 'frontend'
  params: {
    acrName: acrName
    acrResourceGroup: acrResourceGroupName 
    environmentName: baseName
    location: location
    imageName: frontendImageName
    imageVersion: frontendImageVersion
    exposed: true
    targetPort: 5000
  }
}

module backend 'container_http.bicep' = {
  scope: rg
  name: 'backend'
  params: {
    acrName: acrName
    acrResourceGroup: acrResourceGroupName 
    environmentName: baseName
    location: location
    imageName: backendImageName
    imageVersion: backendImageVersion
    exposed: false
    targetPort: 3000
    daprComponents: [
      {
        name: 'statestore'
        type: 'state.azure.cosmosdb'
        version: 'v1'
        metadata: [
          {
            name: 'url'
            value: cosmos.outputs.endpoint
          }
          {
            name: 'database'
            value: cosmosDbName
          }
          {
            name: 'collection'
            value: cosmosContainerName
          }
          {
            name: 'masterKey'
            secretRef: 'masterKey'
          }
        ]
      }
    ]
    secrets: [
      {
        name: 'masterKey'
        value: cosmos.outputs.primaryKey
      }
    ]
  }
}

output frontendUrl string = frontend.outputs.fqdn
