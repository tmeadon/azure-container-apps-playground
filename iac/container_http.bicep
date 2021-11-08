param imageName string
param imageVersion string
param location string
param environmentName string
param acrName string
param acrResourceGroup string = resourceGroup().name
param createRevision bool = true
param exposed bool = false
param targetPort int
param daprComponents array = []
param secrets array = []

var additionalSecrets = [
  {
    name: 'docker-password'
    value: acr.listCredentials().passwords[0].value
  }
]

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
      secrets: union(secrets, additionalSecrets)
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username 
          passwordSecretRef: 'docker-password'
        }
      ]
      ingress: {
        external: exposed
        targetPort: targetPort
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
        appPort: targetPort
        appId: imageName
        components: daprComponents
      }
    }
  }
}

output fqdn string = container.properties.configuration.ingress.fqdn
