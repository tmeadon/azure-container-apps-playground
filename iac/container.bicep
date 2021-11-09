param imageName string
param imageVersion string
param location string
param environmentName string
param acrName string
param acrResourceGroup string = resourceGroup().name
param createRevision bool = true
param exposed bool = false
param targetPort int = 80
param daprComponents array = []
param secrets array = []
param scaleRules array = []
param ingressEnabled bool = true
param env array = []

var ingressRule = {
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
      ingress: ingressEnabled ? ingressRule : null
    }
    template: {
      revisionSuffix: createRevision ? imageVersion : null
      containers: [
        {
          image: '${acr.properties.loginServer}/${imageName}:${imageVersion}' 
          name: imageName
          env: env
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
        rules: scaleRules
      }
      dapr: {
        enabled: true
        appPort: ingressEnabled ? targetPort : null
        appId: imageName
        components: daprComponents
      }
    }
  }
}

output fqdn string = container.properties.configuration.ingress.fqdn
