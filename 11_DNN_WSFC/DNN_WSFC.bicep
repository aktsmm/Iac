// ============================================================================
// Bicep: 2-Node Windows DNN Cluster + AD + Shared Disk + Dev-SKU Bastion
// ============================================================================
// 変更点 2025-05-15
//   • AD 用 VM (同一 SKU / OS)
//   • Premium SSD 共有ディスク (maxShares = 2) 作成 → 両ノードへアタッチ
// ----------------------------------------------------------------------------

// ----------------------------
// Parameters
// ----------------------------
param location string = resourceGroup().location
param vnetName string
param vnetAddressPrefix string
param subnetName string
param subnetAddressPrefix string
param bastionSubnetAddressPrefix string
param vm1Name string
param vm2Name string
param adVmName string // ★追加：AD 用 VM 名
param vmSize string = 'Standard_B2s'
param availabilityZone string = '1'
param adminUsername string
@secure()
param adminPassword string
param bastionName string = 'devBastion'
param bastionPipName string = 'bastion-pip'
param sharedDiskSizeGB int = 128 // ★追加：共有ディスク容量

// ----------------------------
// Public IPs
// ----------------------------
resource vm1Pip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${vm1Name}-pip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource vm2Pip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${vm2Name}-pip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource adPip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  // ★AD 用
  name: '${adVmName}-pip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// ----------------------------
// Subnet-level NSG
// ----------------------------
resource subnetNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${vnetName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-128Range'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '0.0.0.0/1'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'Allow-CommonPorts'
        properties: {
          priority: 1010
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '3389'
            '22'
            '443'
            '80'
          ]
        }
      }
    ]
  }
}

// ----------------------------
// Virtual Network
// ----------------------------
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: [vnetAddressPrefix] }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: { id: subnetNsg.id }
        }
      }
    ]
  }
}

// ----------------------------
// NICs
// ----------------------------
resource vm1Nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vm1Name}-nic'
  location: location
  dependsOn: [vnet]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: vnet.properties.subnets[0].id }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: vm1Pip.id }
        }
      }
    ]
  }
}

resource vm2Nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vm2Name}-nic'
  location: location
  dependsOn: [vnet]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: vnet.properties.subnets[0].id }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: vm2Pip.id }
        }
      }
    ]
  }
}

resource adNic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  // ★AD 用
  name: '${adVmName}-nic'
  location: location
  dependsOn: [vnet]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: vnet.properties.subnets[0].id }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: adPip.id }
        }
      }
    ]
  }
}

// ----------------------------
// Shared Managed Disk (Premium SSD, maxShares = 2)
// ----------------------------
// ----------------------------
// Shared Managed Disk (Premium SSD, maxShares = 2) with Zone Specification
// ----------------------------
resource sharedDisk 'Microsoft.Compute/disks@2022-07-02' = {
  name: 'cluster-shared-disk'
  location: location
  zones: [availabilityZone]
  sku: { name: 'Premium_LRS' }
  properties: {
    creationData: { createOption: 'Empty' }
    diskSizeGB: sharedDiskSizeGB
    maxShares: 2 // 共有アタッチ許可
  }
}

// ----------------------------
// Common Image Reference
// ----------------------------
var winImage = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

// ----------------------------
// VM: Cluster Node 1
// ----------------------------
resource vm1 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vm1Name
  location: location
  zones: [availabilityZone]
  properties: {
    hardwareProfile: { vmSize: vmSize }
    storageProfile: {
      imageReference: winImage
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
      dataDisks: [
        {
          lun: 0
          name: sharedDisk.name
          createOption: 'Attach'
          managedDisk: {
            id: sharedDisk.id
            storageAccountType: 'Premium_LRS'
          }
          caching: 'None'
        }
      ]
    }
    osProfile: {
      computerName: vm1Name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: { networkInterfaces: [{ id: vm1Nic.id }] }
  }
}

// ----------------------------
// VM: Cluster Node 2
// ----------------------------
resource vm2 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vm2Name
  location: location
  zones: [availabilityZone]
  dependsOn: [vm1, sharedDisk]
  properties: {
    hardwareProfile: { vmSize: vmSize }
    storageProfile: {
      imageReference: winImage
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
      dataDisks: [
        {
          lun: 0
          name: sharedDisk.name
          createOption: 'Attach'
          managedDisk: {
            id: sharedDisk.id
            storageAccountType: 'Premium_LRS'
          }
          caching: 'None'
        }
      ]
    }
    osProfile: {
      computerName: vm2Name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: { networkInterfaces: [{ id: vm2Nic.id }] }
  }
}

// ----------------------------
// VM: Active Directory (追加分)
// ----------------------------
resource adVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: adVmName
  location: location
  zones: [availabilityZone]
  properties: {
    hardwareProfile: { vmSize: vmSize }
    storageProfile: {
      imageReference: winImage
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
    }
    osProfile: {
      computerName: adVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: { networkInterfaces: [{ id: adNic.id }] }
  }
}

// ----------------------------
// (オプション) AD 構築スクリプト例
// ----------------------------

var adScriptUris = [
  'https://raw.githubusercontent.com/aktsmm/Scripts/main/ps/ADDS-Setup/Setup-ADDSForest.ps1'
]
var adCommand = 'powershell -ExecutionPolicy Bypass -Command "& { ./Setup-ADDSForest.ps1 -DomainName \'example.com\' -DomainNetbiosName \'EXAMPLE\' -InstallDNS }"'

resource adVmExt 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: adVm
  name: 'setup-ad-ds'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: adScriptUris
      commandToExecute: adCommand
    }
  }
}

// ----------------------------
// Custom Script Extension (Debug Portal) – Cluster Nodes
// ----------------------------
var winScriptUris = [
  'https://raw.githubusercontent.com/aktsmm/Scripts/refs/heads/main/ps/IIS-DebugPortal_Setup/IIS_DebugPortal.ps1'
]
var winCommand = 'powershell -ExecutionPolicy Bypass -Command "& { ./IIS_DebugPortal.ps1 }"'

resource vm1Ext 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm1
  name: 'setup-scripts'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: winScriptUris
      commandToExecute: winCommand
    }
  }
}

resource vm2Ext 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm2
  name: 'setup-scripts'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: winScriptUris
      commandToExecute: winCommand
    }
  }
}

// ----------------------------
// Developer SKU Bastion
// ----------------------------

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
}

// ----------------------------
// Outputs
// ----------------------------
output vm1PublicIP string = vm1Pip.properties.ipAddress
output vm2PublicIP string = vm2Pip.properties.ipAddress
output adPublicIP string = adPip.properties.ipAddress
output sharedDiskId string = sharedDisk.id
