param location string
param vnetAName string
param vnetAAddressPrefix string
param subnetAName string
param subnetAAddressPrefix string
param nsgAName string

param vnetBName string
param vnetBAddressPrefix string
param subnetBName string
param subnetBAddressPrefix string
param nsgBName string

param vmAUbuntuName string
param vmBWin2019Name string

param adminUsername string
@secure()
param adminPassword string


module networkModuleA 'NW.bicep' = {
  name: 'networkModuleA'
  params: {
    nsgName: nsgAName
    location: location
    vnetName: vnetAName
    vnetAddressPrefix: vnetAAddressPrefix
    subnetName: subnetAName
    subnetAddressPrefix: subnetAAddressPrefix
  }
}

module networkModuleB 'NW.bicep' = {
  name: 'networkModuleB'
  params: {
    nsgName: nsgBName
    location: location
    vnetName: vnetBName
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
    subnetId: networkModuleB.outputs.subnetId
  }
  dependsOn: [
    networkModuleB
  ]
}
