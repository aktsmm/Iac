param location string = 'japaneast'
param vnetHubName string = 'Vnet-Hub'
param vnetSpokeName string = 'Vnet-Spoke'
param vnetVpnName string = 'Vnet-Spoke-VPN'
param vpnGatewayName string = 'VpnGw1'
param expressRouteGatewayName string = 'ERGW'  // ExpressRoute Gateway 名
param bastionName string = 'AzureBastion'
param publicIPName string = 'VpnGWPIP'
param firewallPublicIPName string = 'FWPIP'
param vmHubName string = 'Hub-Win'
param vmSpokeName string = 'Spoke-Win'
param vnetHubAddressPrefix string = '10.10.0.0/16'
param vnetSpokeAddressPrefix string = '10.100.0.0/16'
param vnetVpnAddressPrefix string = '10.0.0.0/16'
param bastionSubnetName string = 'AzureBastionSubnet'
param bastionSubnetPrefix string = '10.10.2.0/24'
param vpnMainSubnetName string = 'GatewaySubnet'
param vpnMainSubnetPrefix string = '10.0.1.0/24'
param hubMainSubnetName string = 'Hub-main-Subnet'
param hubMainSubnetPrefix string = '10.10.0.0/24'
param hubFirewallSubnetName string = 'AzureFirewallSubnet'
param hubFirewallSubnetPrefix string = '10.10.3.0/24'
param expressRouteGatewaySubnetName string = 'GatewaySubnet'  // ExpressRoute Gateway Subnet 名
param expressRouteGatewaySubnetPrefix string = '10.10.4.0/24'  // ExpressRoute用のサブネット
param spokeMainSubnetName string = 'spoke-main-Subnet'
param spokeMainSubnetPrefix string = '10.100.0.0/24'
param adminUsername string = 'adminuser'
param adminPassword string = 'Password123!'  // セキュリティのため、セキュアなパラメータに変更することを推奨します

// VNet for Hub
resource vnetHub 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: vnetHubName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetHubAddressPrefix
      ]
    }
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
      {
        name: hubMainSubnetName
        properties: {
          addressPrefix: hubMainSubnetPrefix
        }
      }
      {
        name: hubFirewallSubnetName
        properties: {
          addressPrefix: hubFirewallSubnetPrefix
        }
      }
      {
        name: expressRouteGatewaySubnetName
        properties: {
          addressPrefix: expressRouteGatewaySubnetPrefix
        }
      }
    ]
  }
}

// VNet for Spoke
resource vnetSpoke 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: vnetSpokeName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSpokeAddressPrefix
      ]
    }
    subnets: [
      {
        name: spokeMainSubnetName
        properties: {
          addressPrefix: spokeMainSubnetPrefix
        }
      }
    ]
  }
}

// VNet for VPN
resource vnetVpn 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: vnetVpnName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetVpnAddressPrefix
      ]
    }
    subnets: [
      {
        name: vpnMainSubnetName
        properties: {
          addressPrefix: vpnMainSubnetPrefix
        }
      }
    ]
  }
}

// ExpressRoute Gateway Public IP (not needed for ExpressRoute, but added for example completeness)
resource expressRoutePublicIP 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: '${expressRouteGatewayName}-publicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// ExpressRoute Gateway for VNet-Hub
resource expressRouteGateway 'Microsoft.Network/virtualNetworkGateways@2022-09-01' = {
  name: expressRouteGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'erGatewayConfig'
        properties: {
          subnet: {
            id: vnetHub.properties.subnets[3].id  // VNet-HubのExpressRoute Gatewayサブネットを指定
          }
          publicIPAddress: {
            id: expressRoutePublicIP.id
          }
        }
      }
    ]
    gatewayType: 'ExpressRoute'
    sku: {
      name: 'Standard'
      tier: 'Standard'
    }
    enableBgp: true
  }
}

// VPN Gateway Public IP for VNet-VPN
resource vpnGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: publicIPName
  location: location
  sku: {
    name: 'Standard'  // SKUをStandardに設定
  }
  properties: {
    publicIPAllocationMethod: 'Static'  // Static IPに設定
  }
}

// VPN Gateway for VNet-VPN
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2022-09-01' = {
  name: vpnGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vpngatewayconfig'
        properties: {
          publicIPAddress: {
            id: vpnGatewayPublicIP.id
          }
          subnet: {
            id: vnetVpn.properties.subnets[0].id  // VNet-VPN内のサブネットを指定
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    enableBgp: false
  }
}

// Bastion Host Public IP for VNet-Hub
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: '${bastionName}-publicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Bastion Host for VNet-Hub
resource bastionHost 'Microsoft.Network/bastionHosts@2022-09-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIPConfig'
        properties: {
          subnet: {
            id: vnetHub.properties.subnets[0].id  // VNet-HubのBastionサブネットを指定
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}

// 新しい Public IP for Azure Firewall
resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: firewallPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Azure Firewall in VNet-Hub
resource firewall 'Microsoft.Network/azureFirewalls@2022-09-01' = {
  name: 'AzureFirewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'firewallConfig'
        properties: {
          subnet: {
            id: vnetHub.properties.subnets[2].id  // VNet-Hub内のFirewallサブネットを指定
          }
          publicIPAddress: {
            id: firewallPublicIP.id  // Firewall用の新しいPublic IPを使用
          }
        }
      }
    ]
  }
}

// NIC for Hub VM
resource nicHub 'Microsoft.Network/networkInterfaces@2022-09-01' = {
  name: '${vmHubName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnetHub.properties.subnets[1].id  // VNet-Hubのメインサブネットを参照
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// NIC for Spoke VM
resource nicSpoke 'Microsoft.Network/networkInterfaces@2022-09-01' = {
  name: '${vmSpokeName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnetSpoke.properties.subnets[0].id  // VNet-Spokeのサブネットを参照
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// VM in Hub VNet
resource vmHub 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmHubName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    osProfile: {
      computerName: vmHubName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicHub.id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
  }
}

// VM in Spoke VNet
resource vmSpoke 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmSpokeName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    osProfile: {
      computerName: vmSpokeName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicSpoke.id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
  }
}

// VNet Peering between VNet-Hub and VNet-Spoke
resource vnetPeeringHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${vnetHubName}/to-${vnetSpokeName}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetSpoke.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource vnetPeeringSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${vnetSpokeName}/to-${vnetHubName}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// VNet Peering between VNet-Hub and VNet-Spoke-VPN
resource vnetPeeringHubToVpn 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${vnetHubName}/to-${vnetVpnName}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetVpn.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource vnetPeeringVpnToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${vnetVpnName}/to-${vnetHubName}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}
