targetScope = 'subscription'

param baseName string = 'tmtestaca'
param location string = 'northeurope'
param acrName string = baseName
param acrResourceGroupName string = baseName
param frontendImageName string
param frontendImageVersion string
param backendImageName string
param backendImageVersion string
param workerImageName string
param workerImageVersion string

var cosmosDbName = 'db'
var cosmosContainerName = 'names'
var queueName = 'names'

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

module frontend 'container.bicep' = {
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
    ingressEnabled: true
    targetPort: 5000
  }
}

var stateStoreDaprComponent = {
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
      secretRef: 'masterkey'
    }
    {
      name: 'keyPrefix'
      value: 'name'
    }
  ]
}

module backend 'container.bicep' = {
  scope: rg
  name: 'backend'
  params: {
    acrName: acrName
    acrResourceGroup: acrResourceGroupName 
    environmentName: baseName
    location: location
    imageName: backendImageName
    imageVersion: backendImageVersion
    ingressEnabled: true
    exposed: false
    targetPort: 3000
    daprComponents: [
      stateStoreDaprComponent
    ]
    secrets: [
      {
        name: 'masterkey'
        value: cosmos.outputs.primaryKey
      }
    ]
  }
}

module queue 'storage-queue.bicep' = {
  scope: rg
  name: 'storage-queue'
  params: {
    location: location
    queueName: queueName
    storageName: '${baseName}${uniqueString(rg.id)}'
  }
}

module worker 'container.bicep' = {
  scope: rg
  name: 'worker'
  params: {
    acrName: acrName
    acrResourceGroup: acrResourceGroupName 
    environmentName: baseName
    location: location
    imageName: workerImageName
    imageVersion: workerImageVersion
    exposed: false
    ingressEnabled: false
    daprComponents: [
      stateStoreDaprComponent
    ]
    activeRevisionsMode: 'single'
    scaleRules: [
      {
        name: 'queue-keda-scale'
        custom: {
          type: 'azure-queue'
          metadata: {
            queueName: queueName
            messageCount: '1'
          }
          auth: [
            {
              secretRef: 'storageconnection'
              triggerParameter: 'connection'
            }
          ]
        }
      }
    ]
    env: [
      {
        name: 'STORAGE_CONNECTION'
        secretref: 'storageconnection'
      }
      {
        name: 'QUEUE_NAME'
        value: queueName
      }
    ]
    secrets: [
      {
        name: 'masterkey'
        value: cosmos.outputs.primaryKey
      }
      {
        name: 'storageconnection'
        value: queue.outputs.storageConnection
      }
    ]
  }
}

output frontendUrl string = frontend.outputs.fqdn
