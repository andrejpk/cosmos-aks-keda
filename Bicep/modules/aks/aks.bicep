param basename string

param identity object
param location string = resourceGroup().location
param laworkspaceId string

//param logworkspaceid string  // Uncomment this to configure log analytics workspace

param subnetId string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' = {
  name: '${basename}aks'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: identity
  }
  properties: {
    kubernetesVersion: '1.26.3'
    nodeResourceGroup: '${basename}-aksInfraRG'
    dnsPrefix: '${basename}aks'
    agentPoolProfiles: [
      {
        name: 'default'
        count: 1
        // vmSize: 'Standard_D4s_v3'
        vmSize: 'standard_b4s_v2'
        mode: 'System'
        maxCount: 3
        minCount: 1
        osType: 'Linux'
        osSKU: 'Ubuntu'
        enableAutoScaling: true
        maxPods: 50
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnetId // Uncomment this to configure VNET
        enableNodePublicIP: false
      }
    ]

    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      outboundType: 'loadBalancer'
      dockerBridgeCidr: '172.17.0.1/16'
      dnsServiceIP: '10.0.0.10'
      serviceCidr: '10.0.0.0/16'

    }
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
    enableRBAC: true
    enablePodSecurityPolicy: false
    addonProfiles: {

      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: laworkspaceId
        }
        enabled: true
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
      azurepolicy: {
        enabled: false
      }

    }

    disableLocalAccounts: false
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
  }
}

resource dapr 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  name: 'dapr'
  scope: aksCluster
  properties: {
    extensionType: 'microsoft.dapr'
    scope: {
      cluster: {
        releaseNamespace: 'dapr-system'
      }
    }
    autoUpgradeMinorVersion: true
  }
}

output oidcIssuerUrl string = aksCluster.properties.oidcIssuerProfile.issuerURL
output clusterName string = aksCluster.name
