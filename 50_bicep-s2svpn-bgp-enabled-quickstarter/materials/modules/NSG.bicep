// NSG
param location string
param name string
resource defaultNSG 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: name
  location: location
  properties: {
    // securityRules: [
    //   {
    //     name: 'nsgRule'
    //     properties: {
    //       description: 'description'
    //       protocol: 'Tcp'
    //       sourcePortRange: '*'
    //       destinationPortRange: '*'
    //       sourceAddressPrefix: '*'
    //       destinationAddressPrefix: '*'
    //       access: 'Allow'
    //       priority: 100
    //       direction: 'Inbound'
    //     }
    //   }
    // ]
  }
}
output nsgId string = defaultNSG.id
