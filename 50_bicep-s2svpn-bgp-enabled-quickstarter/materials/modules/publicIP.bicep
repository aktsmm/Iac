param location string
param suffix string
resource publicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
    name: 'pip-${suffix}'
    // name: 'sample-gw-pip'
    location: location
    sku: {
      name: 'Standard'
    }
    properties: {
      publicIPAllocationMethod: 'Static'
    }
  }
