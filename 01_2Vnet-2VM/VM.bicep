param location string = resourceGroup().location
param vmName string
param vmSize string
param adminUsername string
param osImageOffer string 
param osImagePublisher string 
param osImageSku string 
@secure()
param adminPassword string
param osDiskStorageType string 
param osdiskname string = '${vmName}-osdisk' // 文字列補間を使用して、VM名をosdisknameに指定しています
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
  dependsOn: [
    publicIP
  ]
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
  dependsOn: [
    networkInterface
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize // ここにVMサイズを指定
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        name: osdiskname
        managedDisk: {
          storageAccountType: osDiskStorageType
        }
      }
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osImageSku
        version: 'latest'
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
