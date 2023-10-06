targetScope = 'subscription'

// Parameters
param rgName string
param acrName string
param cosmosName string
param location string = deployment().location
param throughput int = 1000
param aksNamespace string = 'cosmosdb-order-processor'
param aksServiceAccount string = 'cosmosdb-order-processor-sa'

var baseName = rgName

module rg 'modules/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

module aksIdentity 'modules/Identity/userassigned.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'managedIdentity'
  params: {
    basename: baseName
    location: location
  }
}

var vnetName = 'aks-VNet'

module vnetAKS 'modules/vnet/vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: vnetName
  params: {
    vnetName: vnetName
    location: location
  }
  dependsOn: [
    rg
  ]
}

resource vnetAKSRes 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: vnetAKS.name
}

module acrDeploy 'modules/acr/acr.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'acrInstance'
  params: {
    acrName: acrName
    principalId: aksIdentity.outputs.principalId
    location: location
  }
}

// Uncomment this to configure log analytics workspace

module akslaworkspace 'modules/laworkspace/la.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'akslaworkspace'
  params: {
    basename: baseName
    location: location
  }
}

module appInsights 'modules/laworkspace/appInsights.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'appInsights'
  params: {
    location: location
    appInsightsName: '${rg.name}-appinsights'
    logAnalyticsWorkspaceId: akslaworkspace.outputs.laworkspaceId
  }
}

resource subnetaks 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: 'aksSubNet'
  parent: vnetAKSRes
}

module aksMangedIDOperator 'modules/Identity/role.bicep' = {
  name: 'aksMangedIDOperator'
  scope: resourceGroup(rg.name)
  params: {
    principalId: aksIdentity.outputs.principalId
    roleGuid: 'f1a07417-d97a-45cb-824c-7a7467783830' //ManagedIdentity Operator Role
  }
}

module aksCluster 'modules/aks/aks.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksCluster'
  dependsOn: [
    aksMangedIDOperator
  ]
  params: {
    location: location
    basename: baseName
    // logworkspaceid: akslaworkspace.outputs.laworkspaceId   // Uncomment this to configure log analytics workspace
    // podBindingSelector: 'cosmosdb-order-processor-identity'
    // podIdentityName: 'cosmosdb-order-processor-identity'
    // podIdentityNamespace: 'cosmosdb-order-processor'
    subnetId: subnetaks.id
    // clientId: aksIdentity.outputs.clientId
    // identityid: aksIdentity.outputs.identityid
    identity: {
      '${aksIdentity.outputs.identityid}': {}
    }
    // principalId: aksIdentity.outputs.principalId
    laworkspaceId: akslaworkspace.outputs.laworkspaceId
  }
}

module aksWorkloadIdentity 'modules/Identity/workload.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'workloadIdentity'
  params: {
    basename: baseName
    location: location
    aksNamespace: aksNamespace
    aksServiceAccount: aksServiceAccount
    oidcIssuer: aksCluster.outputs.oidcIssuerUrl
  }
}

module cosmosdb 'modules/cosmos/cosmos.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'cosmosDB'
  params: {
    location: location
    principalId: aksWorkloadIdentity.outputs.principalId
    accountName: cosmosName
    // subNetId: subnetaks.id // Uncomment this to use VNET
    throughput: throughput
  }
}

module kubeDeployment 'modules/kubernetes/kubernetes.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'kubeDeployment'
  params: {
    aksClusterName: aksCluster.outputs.clusterName
    cosmosDbEndpoint: 'https://sandbox-cosmos-aks-keda.documents.azure.com:443/'
  }
}

output workloadClientId string = aksWorkloadIdentity.outputs.clientId
