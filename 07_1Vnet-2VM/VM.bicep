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
param scriptUrl string = 'https://raw.githubusercontent.com/aktsmm/Scripts/main/ps/Disable_IE%20ESC/disableIEESC.ps1'

// osType パラメータを osImagePublisher の値に基づいて設定
var osType = (osImagePublisher == 'MicrosoftWindowsServer') ? 'Windows' : 'Linux'

// パブリックIPの作成
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${vmName}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// ネットワークインターフェースの作成
resource networkInterface 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: '${vmName}-nic'
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

// 仮想マシンの作成
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

// OS タイプが Windows の場合に Custom Script Extension を適用する
resource customScript 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = if (osType == 'Windows') {
  name: 'CustomScriptExtension'
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      fileUris: [
        scriptUrl
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File $(Split-Path -Leaf $fileUris[0])'
    }
  }
}
