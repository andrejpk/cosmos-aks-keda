@secure()
param kubeConfig string
param cosmosDbEndpoint string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource coreServiceAccount_cosmosdbOrderProcessorSa 'core/ServiceAccount@v1' = {
  metadata: {
    annotations: {
      'azure.workload.identity/client-id': '421a5f51-b908-4a0c-bde2-6c88f8f4a8bb'
    }
    name: 'cosmosdb-order-processor-sa'
  }
}

resource appsDeployment_cosmosdbOrderProcessor 'apps/Deployment@v1' = {
  metadata: {
    name: 'cosmosdb-order-processor'
    labels: {
      aadpodidbinding: 'cosmosdb-order-processor-identity'
      app: 'cosmosdb-order-processor'
    }
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'cosmosdb-order-processor'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'cosmosdb-order-processor'
          aadpodidbinding: 'cosmosdb-order-processor-identity'
          'azure.workload.identity/use': 'true'
        }
      }
      spec: {
        serviceAccountName: 'cosmosdb-order-processor-sa'
        containers: [
          {
            name: 'mycontainer'
            image: 'sandboxcosmosakskeda.azurecr.io/cosmosdb/order-processor:latest'
            imagePullPolicy: 'Always'
            env: [
              {
                name: 'CosmosDbConfig__Endpoint'
                value: cosmosDbEndpoint
              }
              {
                name: 'CosmosDbConfig__LeaseEndpoint'
                value: cosmosDbEndpoint
              }
            ]
          }
        ]
      }
    }
  }
}
