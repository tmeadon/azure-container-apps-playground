targetScope = 'subscription'

param baseName string = 'tmtestaca'
param location string = 'northeurope'
param acrName string = baseName
param acrResourceGroupName string = baseName
param frontendImageName string
param frontendImageVersion string
param backendImageName string
param backendImageVersion string

resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: baseName
  location: location
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
  }
}

output frontendUrl string = frontend.outputs.fqdn
