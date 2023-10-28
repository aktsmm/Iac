param location string
param vmName string
param vmSize string
param adminUsername string
param adminPassword string
param osDiskStorageType string
param subnetId string

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${vmName}-publicip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: '${vmName}-NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        name: 'osdisk'
        managedDisk: {
          storageAccountType: osDiskStorageType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}
