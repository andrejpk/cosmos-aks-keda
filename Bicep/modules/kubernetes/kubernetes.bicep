@secure()
param aksClusterName string
param cosmosDbEndpoint string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' existing = {
  name: aksClusterName
}

var kubeConfg = aksCluster.listClusterAdminCredential().kubeconfigs[0].value

// import 'kubernetes@1.0.0' with {
//   namespace: 'default'
//   kubeConfig: kubeConfg
// } as k8s

// module orderProcessorDeployment './orderprocessor_deploy.bicep' = {
//   name: 'orderProcessorDeployment'
//   params: {
//     kubeConfig: aksCluster.listClusterAdminCredential().kubeconfigs[0].value
//     cosmosDbEndpoint: cosmosDbEndpoint
//   }
// }
