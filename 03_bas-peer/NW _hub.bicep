param location string
param vnetName string
param vnetAddressPrefix string
param subnetName string
param subnetAddressPrefix string
param AzfwsubnetAddressPrefix string
param nsgName string
param bastionHostName string
param azureBastionSubnetAddressPrefix string
param firewallPublicIpName string = 'Azfw-pip'

resource vnetHub 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    
  }
}

resource defaultsubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: subnetName
  parent: vnetHub
  dependsOn: [
    nsg
    vnetHub
  ]
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}





resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: '${bastionHostName}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: 'AzureBastionSubnet'
  parent: vnetHub
  properties: {
    addressPrefix: azureBastionSubnetAddressPrefix
  }
  dependsOn: [
    defaultsubnet
  ]
}


resource bastionHost 'Microsoft.Network/bastionHosts@2022-07-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          subnet: {
            id: '${vnetHub.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: '${bastionHostName}-ipconf'
      }
    ]
  }
  dependsOn: [
    bastionSubnet
  ]
}


resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  
}


//Azure Firewall 周り

resource AZFWSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'AzureFirewallSubnet'
  parent: vnetHub
  properties: {
    addressPrefix: AzfwsubnetAddressPrefix
  }
  dependsOn: [
    bastionSubnet
  ]
}
/*
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: firewallPublicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
*/

//Azure Firewall standardwをいつかaddする



output subnetId string = defaultsubnet.id
output vnetId string = vnetHub.id
