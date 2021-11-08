targetScope = 'subscription'

param baseName string = 'tmtestaca'
param location string = 'northeurope'
param acrName string = baseName
param acrResourceGroupName string = baseName
param frontendImageName string
param frontendImageVersion string

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
  }
}

output frontendUrl string = frontend.outputs.fqdn
