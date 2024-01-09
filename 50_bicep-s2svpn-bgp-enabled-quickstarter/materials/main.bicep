var location = resourceGroup().location

// NSG
resource defaultNSG 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-default'
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

//クラウド想定VNET
resource vpnCloudVNet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vpn-cloud-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'Subnet-1'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: defaultNSG.id
          }
        }
      }
    ]
  }
  //後でサブネットのidを再利用できるように名前を付ける
  resource cloudVNetGatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }
  resource cloudVNetSubnet1 'subnets' existing = {
    name: 'Subnet-1'
  }
}

//オンプレ想定VNET
resource vpnOnpVNet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vpn-onp-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.100.0.0/24'
        }
      }
      {
        name: 'Subnet-1'
        properties: {
          addressPrefix: '10.100.1.0/24'
          networkSecurityGroup: {
            id: defaultNSG.id
          }
        }
      }
    ]
  }
  resource onpVNetGatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }
  resource onpVNetSubnet1 'subnets' existing = {
    name: 'Subnet-1'
  }
}




//リソース構成から名前で参照したいのでPublicIPを個別に宣言
// StandardでStaticにする
// 要対応：なぜかゾーン冗長のパブリックIPが作られてしまう
// API Versionを2022-07-01にすると、ゾーン冗長のパブリックIPが作られなくなる
resource vpngwCloudPIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: '${vpnCloudVNet.name}-gw-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    // publicIPAllocationMethod: 'Dynamic'
    // dnsSettings: {
    //   domainNameLabel: 'dnsname'
    // }
  }
}
// StandardでStaticにする
// 要対応：なぜかゾーン冗長のパブリックIPが作られてしまう->解決した説

resource vpngwOnpPIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: '${vpnOnpVNet.name}-gw-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    // publicIPAllocationMethod: 'Dynamic'
  }
}


//Cloud想定VNETのvpngateway
//standard sku
// 要対応：なぜかゾーン冗長のパブリックIPが作られてしまうため、AZ対応のVPNGatewayを作らざるを得ない
resource vpngwCloud 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: '${vpnCloudVNet.name}-gw'
  location: location
  properties: {
    bgpSettings: {
      asn: 65010
    }
    ipConfigurations: [
      {
        name: '${vpnCloudVNet.name}-gw-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vpnCloudVNet::cloudVNetGatewaySubnet.id
          }
          publicIPAddress: {
            id: vpngwCloudPIP.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
  }
}

// オンプレ側想定VNETのvpn gateway
// 要対応：なぜかゾーン冗長のパブリックIPが作られてしまうため、AZ対応のVPNGatewayを作らざるを得ない
resource vpngwOnp 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: '${vpnOnpVNet.name}-gw'
  location: location
  properties: {
    bgpSettings: {
      asn: 65020
    }
    ipConfigurations: [
      {
        name: '${vpnOnpVNet.name}-gw-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vpnOnpVNet::onpVNetGatewaySubnet.id
          }
          publicIPAddress: {
            id: vpngwOnpPIP.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
  }
}

//クラウド側VPNGatewayのlocal network gateway
resource vpngwCloudLNG 'Microsoft.Network/localNetworkGateways@2019-11-01' = {
  name: '${vpngwCloud.name}-lng'
  location: location
  properties: {
    bgpSettings:{
      asn: 65010
      bgpPeeringAddress: vpngwCloud.properties.bgpSettings.bgpPeeringAddress
    }
    // localNetworkAddressSpace: {
    //   addressPrefixes: [
    //     'REQUIRED'
    //   ]
    // }
    gatewayIpAddress: vpngwCloudPIP.properties.ipAddress
  }
}

// オンプレ側VPNGatewayのLocal Network Gateway
resource vpngwOnpLNG 'Microsoft.Network/localNetworkGateways@2019-11-01' = {
  name: '${vpngwOnp.name}-lng'
  location: location
  properties: {
    bgpSettings:{
      asn: 65020
      bgpPeeringAddress: vpngwOnp.properties.bgpSettings.bgpPeeringAddress
    }
    // localNetworkAddressSpace: {
    //   addressPrefixes: [
    //     'REQUIRED'
    //   ]
    // }
    gatewayIpAddress: vpngwOnpPIP.properties.ipAddress
  }
}

// クラウド->オンプレへの接続
resource conncetionCloudtoOnp 'Microsoft.Network/connections@2020-11-01' = {
  name: 'fromCloudtoOnp'
  location: location
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: vpngwCloud.id
      properties:{}
    }
    localNetworkGateway2: {
      id: vpngwOnpLNG.id
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: 'zukako'
  }
}

// オンプレ->クラウドへの接続
resource connectionOnptoCloud 'Microsoft.Network/connections@2020-11-01' = {
  name: 'fromOnptoCloud'
  location: location
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: vpngwOnp.id
      properties:{}
    }
    localNetworkGateway2: {
      id: vpngwCloudLNG.id
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: 'zukako'
  }
}


// クラウドおよびオンプレVNETにVM作成
resource cloudvmnic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'cloudvmnic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vpnCloudVNet::cloudVNetSubnet1.id
          }
        }
      }
    ]
  }
}

resource ubuntuCloudVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'cloud-ubuntu-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A2_v2'
    }
    osProfile: {
      computerName: 'cloudubuntu'
      adminUsername: 'AzureAdmin'
      adminPassword: 'P@ssw0rd#20221214'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'cloudUbuntu-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: cloudvmnic.id
        }
      ]
    }
    // diagnosticsProfile: {
    //   bootDiagnostics: {
    //     enabled: true
    //     storageUri: 'storageUri'
    //   }
    // }
  }
}

resource onpvmnic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'onpvmnic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vpnOnpVNet::onpVNetSubnet1.id
          }
        }
      }
    ]
  }
}

resource ubuntuOnpVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'onp-ubuntu-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A2_v2'
    }
    osProfile: {
      computerName: 'onpubuntu'
      adminUsername: 'AzureAdmin'
      adminPassword: 'P@ssw0rd#20221214'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'onpUbuntu-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: onpvmnic.id
        }
      ]
    }
    // diagnosticsProfile: {
    //   bootDiagnostics: {
    //     enabled: true
    //     storageUri: 'storageUri'
    //   }
    // }
  }
}
