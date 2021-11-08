param imageName string
param imageVersion string
param location string
param environmentName string
param acrName string
param acrResourceGroup string = resourceGroup().name
param createRevision bool = true

resource environment 'Microsoft.Web/kubeEnvironments@2021-02-01' existing = {
  name: environmentName
}

resource acr 'Microsoft.ContainerRegistry/registries@2019-05-01' existing = {
  name: acrName
  scope: resourceGroup(acrResourceGroup)
}

resource container 'Microsoft.Web/containerApps@2021-03-01' = {
  name: imageName
  kind: 'containerapp'
  location: location
  properties: {
    kubeEnvironmentId: environment.id
    configuration: {
      secrets: [
        {
          name: 'docker-password'
          value: acr.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username 
          passwordSecretRef: 'docker-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      revisionSuffix: createRevision ? imageVersion : null
      containers: [
        {
          image: '${acr.properties.loginServer}/${imageName}:${imageVersion}' 
          name: imageName
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 2
      }
      dapr: {
        enabled: true
        appPort: 80
        appId: imageName
        components: []
      }
    }
  }
}

output fqdn string = container.properties.configuration.ingress.fqdn
