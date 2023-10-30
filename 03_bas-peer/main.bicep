param location string
param VnetAName string 
param VnetBName string 

param vnetAAddressPrefix string 
param subnetAName string ='${VnetAName}-Subnet'
param subnetAAddressPrefix string
param nsgAName string='${VnetAName}-nsg'

param vnetBAddressPrefix string
param subnetBName string='${VnetBName}-Subnet'
param subnetBAddressPrefix string
param nsgBName string='${VnetBName}-nsg'

param vmAUbuntuName string='${VnetAName}-Ubu'
param vmBWin2019Name string='${VnetAName}-Win'
param vmCWin2019Name string='${VnetBName}-Win'
param adminUsername string
@secure()
param adminPassword string

param bastionHostName string='${VnetAName}-bastion'
param azureBastionSubnetAddressPrefix string
param AzfwsubnetAddressPrefix string


module networkModuleA 'NW _hub.bicep' = {
  name: 'networkModuleA'
  params: {
    azureBastionSubnetAddressPrefix:azureBastionSubnetAddressPrefix
    nsgName: nsgAName
    bastionHostName:bastionHostName
    location: location
    vnetName: VnetAName
    vnetAddressPrefix: vnetAAddressPrefix
    subnetName: subnetAName
    subnetAddressPrefix: subnetAAddressPrefix
    AzfwsubnetAddressPrefix:AzfwsubnetAddressPrefix
  }
}

module networkModuleB 'NW.bicep' = {
  name: 'networkModuleB'
  params: {
    nsgName: nsgBName
    location: location
    vnetName: VnetBName
    vnetAddressPrefix: vnetBAddressPrefix
    subnetName: subnetBName
    subnetAddressPrefix: subnetBAddressPrefix
  }
}

module vmModuleA_Ubuntu 'VM.bicep' = {
  name: 'vmModuleA_Ubuntu'
  params: {
    location: location
    vmName: vmAUbuntuName
    vmSize: 'Standard_B2ms'
    osImageOffer: '0001-com-ubuntu-minimal-focal'
    osImagePublisher: 'Canonical'
    osImageSku: 'minimal-20_04-lts'
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskStorageType:'StandardSSD_LRS'
    subnetId: networkModuleA.outputs.subnetId
  }
  dependsOn: [
    networkModuleA
  ]
}


module vmModuleB_Windows 'VM.bicep' = {
  name: 'vmModuleB_Windows'
  params: {
    location: location
    vmName: vmBWin2019Name
    vmSize: 'Standard_B2ms'
    osImageOffer: 'WindowsServer'
    osImagePublisher: 'MicrosoftWindowsServer'
    osImageSku: '2019-Datacenter'
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskStorageType: 'StandardSSD_LRS'
    subnetId: networkModuleA.outputs.subnetId
  }
  dependsOn: [
    networkModuleA
  ]
}

module vmModuleC_Windows 'VM.bicep' = {
  name: 'vmModuleC_Windows'
  params: {
    location: location
    vmName: vmCWin2019Name
    vmSize: 'Standard_B2ms'
    osImageOffer: 'WindowsServer'
    osImagePublisher: 'MicrosoftWindowsServer'
    osImageSku: '2019-Datacenter'
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskStorageType: 'StandardSSD_LRS'
    subnetId: networkModuleB.outputs.subnetId
  }
  dependsOn: [
    networkModuleB
  ]
}

output vnetAId string = networkModuleA.outputs.vnetId
output vnetBId string = networkModuleB.outputs.vnetId


resource vNetHubSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${VnetAName}/to${VnetBName}'
  properties: {
    remoteVirtualNetwork: {
      id: networkModuleB.outputs.vnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    networkModuleB
    networkModuleA
  ]
}

resource vnNetSpokeHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${VnetBName}/to${VnetAName}'
  properties: {
    remoteVirtualNetwork: {
      id:  networkModuleA.outputs.vnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    networkModuleB
  ]
}






