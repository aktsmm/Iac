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
param gatewaySubnetAddress string
param gatewaypublicIpName string
param hubvpnGatewayName string

param vpngwsku string



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
    //nsg
  ]
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource Gatewysubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'gatewaySubnet'
  parent: vnetHub
       properties: {
      addressPrefix: gatewaySubnetAddress
  }
}

output GWsubnetId string = Gatewysubnet.id


resource vpngwPublicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: gatewaypublicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Standard'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-04-01' = {
  name: hubvpnGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        id: 'string'
        name: 'string'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vpngwPublicIP.id
          }
          subnet: {
            id: Gatewysubnet.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: vpngwsku
      tier: vpngwsku
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
  dependsOn: [
    defaultsubnet
  ]
  properties: {
    addressPrefix: azureBastionSubnetAddressPrefix
  }
}


resource bastionHost 'Microsoft.Network/bastionHosts@2022-07-01' = {
  name: bastionHostName
  location: location
  dependsOn: [
    bastionSubnet
  ]
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
        name: 'ipconfig1'
      }
    ]
  }
}


resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  
}


//Azure Firewall 周り

resource AZFWSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'AzureFirewallSubnet'
  dependsOn: [
    bastionSubnet
  ]
  parent: vnetHub
  properties: {
    addressPrefix: AzfwsubnetAddressPrefix
  }
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



output vpngwpublicIpId string = vpngwPublicIP.id
output vpngwId string = vpnGateway.id

output subnetId string = defaultsubnet.id
output vnetId string = vnetHub.id
