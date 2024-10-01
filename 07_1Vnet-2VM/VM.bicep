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
  name: '${vmName}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

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

// ここから追加: IE Enhanced Security Configurationを無効化するrunCommand
resource disableIEESCVM 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  name: 'disableIEESCVM'
  location: location
  parent: vm
  properties: {
    source: {
      script: '''
        # IE Enhanced Security Configurationを無効化するスクリプト
        Write-Output "Disabling IE Enhanced Security Configuration for Administrators and Users"

        # 管理者用のIE ESCを無効化
        $AdminKey = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A66A0D1F-9C7D-11D0-9155-00AA00C3EABA}'
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0

        # ユーザー用のIE ESCを無効化
        $UserKey = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A66A0D20-9C7D-11D0-9155-00AA00C3EABA}'
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

        # エクスプローラーを再起動して設定を反映
        Stop-Process -Name explorer -Force

        Write-Output "IE Enhanced Security Configuration has been disabled successfully."

        # Azure CLI と Azure PowerShell をワンコマンドでダウンロード＆インストール（確認プロンプト自動応答）
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
        Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name='Microsoft Azure CLI'" | ForEach-Object { $_.Uninstall() }
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLISetup.msi; Start-Process msiexec.exe -ArgumentList '/I AzureCLISetup.msi /quiet /norestart' -Wait; Remove-Item -Force .\AzureCLISetup.msi
        Install-Module -Name Az -Repository PSGallery -Force -Scope AllUsers -Confirm:$false -SkipPublisherCheck
      '''
    }
    runAsUser: 'SYSTEM' // SYSTEMユーザー権限で実行
  }
}
