param appInsightsName string
param logAnalyticsWorkspaceId string
param location string = resourceGroup().location

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    ApplicationId: appInsightsName
    Request_Source: 'IbizaWebAppExtensionCreate'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

output appInsightsId string = appInsights.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString

// resource appInsightsLinkedService 'Microsoft.OperationalInsights/workspaces/datasources@202 = {
//   name: '${logAnalyticsWorkspaceId}/Microsoft.Insights/components/${appInsightsName}'
//   properties: {
//     linkedResourceId: appInsights.id
//     dataSourceType: 'AzureMonitor'
//     dataSourceProperties: {
//       azureMonitorProperties: {
//         sourceId: appInsights.id
//       }
//     }
//   }
// }
