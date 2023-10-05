param basename string
param location string = resourceGroup().location
resource logworkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview'= {
  name: '${basename}-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}

output laworkspaceId string = logworkspace.id
