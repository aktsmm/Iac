param location string = resourceGroup().location
param adminUsername string = 'adminuser' // 管理者ユーザー名
param adminPassword string = 'Password123!'  // セキュリティのため、セキュアなパラメータに変更することを推奨します
param domainName string = 'contoso.com' // Active Directory ドメイン名
param adVmName string = 'ADVM' // Active Directory VM の名前
param wsfcVmNamePrefix string = 'WSFCVM' // WSFC VM の名前のプレフィックス
param numberOfWsfcNodes int = 2 // WSFC VM の数
param vnetName string = 'WSFC-VNet' // 仮想ネットワークの名前
param subnetName string = 'WSFC-Subnet' // サブネットの名前
param vmSize string = 'Standard_B2ms' // VM のサイズ
param diskType string = 'StandardSSD_LRS' // ディスクの種類
param bastionPipName string = 'BastionPIP' // Bastion ホストのパブリック IP アドレスの名前

// ネットワークセキュリティグループ（NSG）の作成
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'WSFC-NSG'
  location: location
  properties: {
    securityRules: [
      // RDP (TCP 3389)
      {
        name: 'Allow-RDP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      // SSH (TCP 22)
      {
        name: 'Allow-SSH'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      // HTTP (TCP 80)
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      // HTTPS (TCP 443)
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 400
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      // Outbound - Allow all
      {
        name: 'Allow-All-Outbound'
        properties: {
          priority: 500
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}


// 仮想ネットワークの作成
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      // Azure Bastion 用のサブネットを追加
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

// AD VMのNICを作成
resource adNic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: '${adVmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// AD VMの作成
resource adVm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: adVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: adVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: adNic.id
        }
      ]
    }
  }
}

// AD VMでADDSをインストールするためのrunCommand
resource adRunCommand 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  name: 'InstallADDS'
  location: location
  parent: adVm
  properties: {
    source: {
      script: '''
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools;
        Install-ADDSForest -DomainName "${domainName}" -SafeModeAdministratorPassword (ConvertTo-SecureString "${adminPassword}" -AsPlainText -Force)
      '''
    }
  }
}

// Bastion用のパブリックIPアドレス
resource bastionPip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: bastionPipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Bastionホストの作成
resource bastionHost 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: 'BastionHost'
  location: 'japaneast'  // 東日本リージョン
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIPConfig'
        properties: {
          publicIPAddress: {
            id: bastionPip.id
          }
          subnet: {
            id: vnet.properties.subnets[1].id  // AzureBastionSubnet を指定
          }
        }
      }
    ]
  }
}

// WSFC VMのNICをまとめて作成し、ロードバランサーのバックエンドプールに追加
resource wsfcNics 'Microsoft.Network/networkInterfaces@2021-03-01' = [for i in range(0, numberOfWsfcNodes): {
  name: '${wsfcVmNamePrefix}${i + 1}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id  // 仮想ネットワークのサブネットを参照
          }
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: [
            {
              id: loadBalancer.properties.backendAddressPools[0].id  // ロードバランサーのバックエンドプールを参照
            }
          ]
        }
      }
    ]
  }
}]

// 共有ディスクの作成
resource sharedDisk 'Microsoft.Compute/disks@2023-04-02' = {
  name: 'WSFCSharedDisk'
  location: location
  sku: {
    name: diskType
  }
  properties: {
    diskSizeGB: 1024
    creationData: {
      createOption: 'Empty'
    }
    maxShares: numberOfWsfcNodes
  }
}

// WSFC VM1の作成
resource wsfcVm1 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: '${wsfcVmNamePrefix}1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${wsfcVmNamePrefix}1'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Attach'
          managedDisk: {
            id: sharedDisk.id
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: wsfcNics[0].id  // WSFC VM1 の NIC を指定
        }
      ]
    }
  }
}

// WSFC VM2の作成 (VM1に依存)
resource wsfcVm2 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: '${wsfcVmNamePrefix}2'
  location: location
  dependsOn: [
    wsfcVm1  // WSFC VM1が作成されてからWSFC VM2を作成
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${wsfcVmNamePrefix}2'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Attach'
          managedDisk: {
            id: sharedDisk.id
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: wsfcNics[1].id  // WSFC VM2 の NIC を指定
        }
      ]
    }
  }
}

// 内部ロードバランサーの作成
resource loadBalancer 'Microsoft.Network/loadBalancers@2021-03-01' = {
  name: 'WSFC-ILB'
  location: location
  sku: {
    name: 'Standard'  // 内部LBでは Standard SKU を推奨
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          // サブネット内の内部IPを使用
          subnet: {
            id: vnet.properties.subnets[0].id  // 仮想ネットワークのサブネットを参照
          }
          privateIPAddress: '10.0.0.5'  // 内部ロードバランサー用のプライベートIP
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'WSFCBackendPool'  // バックエンドプールの定義
      }
    ]
    loadBalancingRules: [
      {
        name: 'WSFC-ILB-Rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'WSFC-ILB', 'LoadBalancerFrontend')  // フロントエンドIP構成の参照
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'WSFC-ILB', 'WSFCBackendPool')  // バックエンドプールの参照
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'WSFC-ILB', 'WSFC-HealthProbe')  // ヘルスプローブの参照
          }
          protocol: 'Tcp'
          frontendPort: 1433  // WSFCで使用するポート
          backendPort: 1433
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
          loadDistribution: 'Default'
        }
      }
    ]
    // ヘルスプローブをロードバランサー内に直接定義
    probes: [
      {
        name: 'WSFC-HealthProbe'
        properties: {
          protocol: 'Tcp'
          port: 1433
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

// ここから追加: AD VMでIE Enhanced Security Configurationを無効化するrunCommand
resource disableIEESCADVM 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  name: 'disableIEESCADVM'
  location: location
  parent: adVm
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
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLISetup.msi; Start-Process msiexec.exe -ArgumentList '/I AzureCLISetup.msi /quiet /norestart' -Wait; Remove-Item -Force .\AzureCLISetup.msi; Install-Module -Name Az -Repository PSGallery -Force -Scope AllUsers -Confirm:$false -SkipPublisherCheck

      '''
    }
    runAsUser: 'SYSTEM' // SYSTEMユーザー権限で実行
  }
  dependsOn: [
    adRunCommand // ADDSのインストール完了後に実行する
  ]
}

// ここから追加: AD VMでIE Enhanced Security Configurationを無効化するrunCommand
resource disableIEESCwsfcVm1 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  name: 'DisableIEESCwsfcVm1'
  location: location
  parent: wsfcVm1
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
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLISetup.msi; Start-Process msiexec.exe -ArgumentList '/I AzureCLISetup.msi /quiet /norestart' -Wait; Remove-Item -Force .\AzureCLISetup.msi; Install-Module -Name Az -Repository PSGallery -Force -Scope AllUsers -Confirm:$false -SkipPublisherCheck

      '''
    }
    runAsUser: 'SYSTEM' // SYSTEMユーザー権限で実行
  }
}

// ここから追加: AD VMでIE Enhanced Security Configurationを無効化するrunCommand
resource disableIEESCwsfcVm2 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  name: 'DisableIEESCwsfcVm2'
  location: location
  parent: wsfcVm2
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
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLISetup.msi; Start-Process msiexec.exe -ArgumentList '/I AzureCLISetup.msi /quiet /norestart' -Wait; Remove-Item -Force .\AzureCLISetup.msi; Install-Module -Name Az -Repository PSGallery -Force -Scope AllUsers -Confirm:$false -SkipPublisherCheck


      '''
    }
    runAsUser: 'SYSTEM' // SYSTEMユーザー権限で実行
  }
}
