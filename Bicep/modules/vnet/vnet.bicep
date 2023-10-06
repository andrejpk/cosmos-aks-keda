param location string = resourceGroup().location
param vnetName string

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: 'aksSubNet'
        properties: {
          addressPrefix: '10.240.0.0/16'
          //remove Service Endpoints if you want to use public endpoint for Cosmos
          serviceEndpoints: [
            {
              service: 'Microsoft.AzureCosmosDB'
              locations: [
                location
              ]
            }
          ]
        }
      }
    ]
  }
}
output vnetId string = vnet.id
output vnetName string = vnet.name
output vnetSubnets array = vnet.properties.subnets
output vnetSubnetId string = vnet.properties.subnets[0].id
