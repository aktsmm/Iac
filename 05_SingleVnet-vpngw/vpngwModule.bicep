// vpngwModule.bicep

param location string
param publicIpName string
param vpngwName string
param vnetId string
param subnetId string
param vpngwsku string
resource publicIp 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: publicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

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
            id: subnetId
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

output publicIpId string = publicIp.id
output vpnGatewayId string = vpnGateway.id
output subnetId string = subnetId
output vnetId string = vnetId
