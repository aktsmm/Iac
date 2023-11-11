// main.bicep

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

module vpngwModule './vpngwModule.bicep' = {
  name: 'vpngwModule'
  params: {
    location: location
    publicIpName: publicIpName
    vpngwName: vpngwName
    vnetId: vnet.id
    subnetId: vnet.properties.subnets[0].id
    vpngwsku: vpngwsku
  }
}



output vnetId string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
output publicIpId string = vpngwModule.outputs.publicIpId
output vpnGatewayId string = vpngwModule.outputs.vpnGatewayId
