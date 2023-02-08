@description('The principal Id of the object that will be granted the needed role.')
param principalId string

@description('This is the built-in Reader role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles?WT.mc_id=AZ-MVP-5003548#reader')
resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

targetScope = 'subscription'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(readerRoleDefinition.id, principalId, readerRoleDefinition.id)
  properties: {
    roleDefinitionId: readerRoleDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
