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

// WSFC VMのNICをまとめて作成
resource wsfcNics 'Microsoft.Network/networkInterfaces@2021-03-01' = [for i in range(0, numberOfWsfcNodes): {
  name: '${wsfcVmNamePrefix}${i + 1}-nic'
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


