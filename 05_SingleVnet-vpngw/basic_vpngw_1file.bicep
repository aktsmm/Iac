param location string// = 'japaneast'
param VnetName string //= 'Vnet-Hub'
param vpngwName string //= 'vpngw'
param publicIpName string = '${vpngwName}-pip'
param gatewaySubnetAddress string //= '10.0.100.0/24'
param VnetAddress string //= '10.0.0.0/16'
@allowed([
  'VpnGw1'
  'basic'
])
param vpngwsku string //= 'VpnGw1'


resource vnet 'Microsoft.Network/virtualNetworks@2018-11-01' = {
  name: VnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        VnetAddress
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetAddress
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: publicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}



/*
  Creates a virtual network gateway resource.
*/
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2018-11-01' = {
  name: vpngwName
  location: location
  properties: {
    ipConfigurations: [
      {
        id: 'string'
        name: 'string'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: vnet.properties.subnets[0].id
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
