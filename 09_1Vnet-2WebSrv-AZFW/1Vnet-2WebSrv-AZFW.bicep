param location string = resourceGroup().location
param vnetName string
param subnetName string
param firewallSubnetName string = 'AzureFirewallSubnet'
param vnetAddressPrefix string
param subnetAddressPrefix string
param bastionSubnetAddressPrefix string
param firewallSubnetAddressPrefix string
param WebSrvWinName string
param WebSrvubuname string
param adminUsername string
@secure()
param adminPassword string
param firewallName string
param firewallPublicIPName string
param bastionName string
param bastionPublicIPName string
param bastionSubnetName string

// Public IP for VMs
resource WebSrvWinPublicIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: '${WebSrvWinName}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource WebSrvubuPublicIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: '${WebSrvubuname}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource vmNSG 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: '${vnetName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 1010
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-SSH'
        properties: {
          priority: 1020
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'Allow-RDP'
        properties: {
          priority: 1030
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

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
          networkSecurityGroup: {
            id: vmNSG.id
          }
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
        }
      }
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: firewallSubnetAddressPrefix
        }
      }
    ]
  }
}

resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: firewallPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: bastionPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-05-01' = {
  name: firewallName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'AzureFirewallIpConfig'
        properties: {
          publicIPAddress: {
            id: firewallPublicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, firewallSubnetName)
          }
        }
      }
    ]
    threatIntelMode: 'Alert'
    networkRuleCollections: [
      {
        name: 'AllowAllOutbound'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowAllOutboundRule'
              sourceAddresses: ['*']
              destinationAddresses: ['*']
              destinationPorts: ['*']
              protocols: ['Any']
            }
          ]
        }
      }
    ]
  }
}

resource WebSrvWinNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${WebSrvWinName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: WebSrvWinPublicIP.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}

resource WebSrvubuNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${WebSrvubuname}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: WebSrvubuPublicIP.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}

resource WebSrvWin 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: WebSrvWinName
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
      computerName: WebSrvWinName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: WebSrvWinNic.id
        }
      ]
    }
  }
}

resource WebSrvubu 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'WebSrvubu'
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
      computerName: WebSrvubuname
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: WebSrvubuNic.id
        }
      ]
    }
  }
  dependsOn: [
    WebSrvubuNic
  ]
}

resource WebSrvubuScript 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: 'WebSrvubu/customScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/aktsmm/Scripts/refs/heads/main/bash/Make_Squid_nginx_http(s)Srv/setup-squid-nginx.sh'
      ]
      commandToExecute: 'bash setup-squid-nginx.sh'
    }
  }
  dependsOn: [
    WebSrvubu
  ]
}

resource WinVMDebugScript 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: '${WebSrvWin.name}/customScript'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/aktsmm/Scripts/refs/heads/main/ps/IIS-DebugPortal_Setup/IIS_DebugPortal.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Bypass -File IIS_DebugPortal.ps1'
    }
  }
  dependsOn: [
    WebSrvWin
  ]
}

resource bastion 'Microsoft.Network/bastionHosts@2022-05-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Developer'
  }
  properties: any({
    virtualNetwork: {
      id: vnet.id
    }
  })
  dependsOn: [
    vnet
  ]
}

resource routeTable 'Microsoft.Network/routeTables@2022-05-01' = {
  name: '${vnetName}-routeTable'
  location: location
  properties: {
    routes: [
      {
        name: 'defaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}
