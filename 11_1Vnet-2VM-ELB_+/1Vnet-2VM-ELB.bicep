param location string = resourceGroup().location
param vnetName string 
param subnetName string 
param vnetAddressPrefix string 
param subnetAddressPrefix string 
param ubuvmName string 
param WinvmName string
param adminUsername string 
@secure()
param adminPassword string
param elbName string 
param elbPublicIPName string 
param bastionName string

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          // NSGをサブネットに関連付け
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      // Developer SKUではAzureBastionSubnetは不要
    ]
  }
}

resource elbPublicIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: elbPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource elb 'Microsoft.Network/loadBalancers@2022-05-01' = {
  name: elbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: elbPublicIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool'
      }
    ]
    // ヘルスプローブの追加（VMの健全性チェック用）
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    // ロードバランシング規則の追加
    loadBalancingRules: [
      {
        name: 'lbRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', elbName, 'LoadBalancerFrontEnd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', elbName, 'BackendPool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', elbName, 'tcpProbe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 4
        }
      }
    ]
  }
}

// ネットワークセキュリティグループ（NSG）の作成
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: '${vnetName}-nsg'
  location: location
  properties: {
    securityRules: [
      // HTTP (80)
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      // HTTPS (443)
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 1001
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      // SSH (22)
      {
        name: 'Allow-SSH'
        properties: {
          priority: 1002
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      // RDP (3389)
      {
        name: 'Allow-RDP'
        properties: {
          priority: 1003
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  parent: vnet
  name: subnetName
}


resource windowsVMNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${WinvmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          // ロードバランサーのバックエンドプールに関連付け
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', elbName, 'BackendPool')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    elb  // ロードバランサーが先に作成されるように依存関係を設定
  ]
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: WinvmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: WinvmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: windowsVMNic.id
        }
      ]
    }
  }
}

// Windows VMでIISデバッグポータルセットアップスクリプトを実行
resource windowsVMExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: 'CustomScriptExtension'
  location: location
  parent: windowsVM
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/aktsmm/Scripts/main/ps/IIS-DebugPortal_Setup/IIS_DebugPortal.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File IIS_DebugPortal.ps1'
    }
  }
}

resource ubunic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${ubuvmName}-ubunic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          // ロードバランサーのバックエンドプールに関連付け
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', elbName, 'BackendPool')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    elb  // ロードバランサーが先に作成されるように依存関係を設定
  ]
}

resource ubuvm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: ubuvmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: ubuvmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      // SSH認証を無効化してパスワード認証を有効化
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ubunic.id
        }
      ]
    }
  }
}

// Ubuntu VMでSquid+Nginxセットアップスクリプトを実行
resource ubuvmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: 'CustomScript'
  location: location
  parent: ubuvm
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/aktsmm/Scripts/main/bash/Make_Squid_nginx_http(s)Srv/setup-squid-nginx.sh'
      ]
      commandToExecute: 'bash setup-squid-nginx.sh'
    }
  }
}

// 不要になったバックエンドプールリソースを削除（ロードバランサー定義内で作成されるため）
// resource backendPool 'Microsoft.Network/loadBalancers/backendAddressPools@2023-11-01' = {
//   name: 'BackendPool'
//   parent: elb
// }


resource bastion 'Microsoft.Network/bastionHosts@2022-05-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Developer'  // Developer SKUを使用（Public IP不要、コスト効率重視）
  }
  properties: any({
    virtualNetwork: {
      id: vnet.id
    }
  })
}
