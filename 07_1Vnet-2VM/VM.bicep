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
param osdiskname string = '${vmName}-osdisk'
param subnetId string

// osType パラメータを osImagePublisher の値に基づいて設定
var osType = (osImagePublisher == 'MicrosoftWindowsServer') ? 'Windows' : 'Linux'

// パブリックIPの作成
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${vmName}-pip'
  location: location
  sku: {
    name: 'Standard' // Standard SKU を指定
  }
  properties: {
    publicIPAllocationMethod: 'static' 
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
      // スクリプトの内容を直接 PowerShell コマンドに埋め込む
      commandToExecute: '''
        powershell.exe -ExecutionPolicy Unrestricted -Command "
        # 管理者用およびユーザー用のレジストリキーを設定
        $AdminKey = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}';
        $UserKey = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}';

        # 管理者用 IE ESC を無効化
        Set-ItemProperty -Path $AdminKey -Name 'IsInstalled' -Value 0;

        # ユーザー用 IE ESC を無効化
        Set-ItemProperty -Path $UserKey -Name 'IsInstalled' -Value 0;

        # エクスプローラーを再起動して設定を反映
        Stop-Process -Name explorer -Force;"
      '''
    }
  }
}
