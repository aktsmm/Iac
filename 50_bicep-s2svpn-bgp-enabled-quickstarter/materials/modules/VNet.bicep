param location string
param nsgId string
// ここもクラウドとオンプレを分割してもいいかも
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
            id: nsgId
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
            id: nsgId
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
