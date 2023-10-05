param basename string
param location string = resourceGroup().location
param oidcIssuer string
param aksNamespace string
param aksServiceAccount string

resource workloadidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${basename}workloadidentity'
  location: location  
}

resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: '${basename}federatedCredential'
  parent: workloadidentity
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: oidcIssuer
    subject: 'system:serviceaccount:${aksNamespace}:${aksServiceAccount}'
  }
}

output identityid string = workloadidentity.id
output clientId string = workloadidentity.properties.clientId
output principalId string = workloadidentity.properties.principalId

