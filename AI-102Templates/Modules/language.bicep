param location string

var roleDefinitionId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var unique = uniqueString(resourceGroup().id, subscription().id, deployment().name)

// Storage resources
resource str 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'str${unique}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: true
  }
  resource blobServices 'blobServices@2023-01-01' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: [
          {
            allowedOrigins: ['https://language.cognitive.azure.com']
            allowedMethods: ['DELETE', 'GET', 'POST', 'OPTIONS', 'PUT']
            allowedHeaders: ['*']
            exposedHeaders: ['*']
            maxAgeInSeconds: 500
          }
        ]
      }
    }
    resource classContainer 'containers@2023-01-01' = {
      name: 'classification'
      properties: {
        publicAccess: 'Blob'
      }
    }
    resource entityContainer 'containers@2023-01-01' = {
      name: 'entityrecognition'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

// Speech resource
resource speech 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'speech${unique}'
  location: location
  kind: 'SpeechServices'
  sku: {
    name: 'S0'
  }
}

// Translate resource
resource translation 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'translation${unique}'
  location: 'global'
  kind: 'TextTranslation'
  sku: {
    name: 'S1'
  }
}

// Search resource
resource search 'Microsoft.Search/searchServices@2024-03-01-preview' = {
  name: 'search${unique}'
  location: location
  sku: {
    name: 'basic'
  }
  properties: {
    hostingMode: 'default'
    replicaCount: 1
    partitionCount: 1
    semanticSearch: 'disabled'
  }
}

// Language resource
resource language 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'language${unique}'
  location: location
  sku: {
    name: 'S'
  }
  kind: 'TextAnalytics'
  identity: {
    type: 'SystemAssigned'
  }
  
  properties: {
    userOwnedStorage: [
      {
        resourceId: str.id
      }
    ]
    apiProperties: {
      qnaAzureSearchEndpointId: search.id
    }
  }
}

// Set up Storage Blob Data Owner permissions
module roleAssignment 'languageroleassignment.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: language.identity.principalId
    roleDefinitionId: roleDefinitionId
    strName: str.name
  }
}
