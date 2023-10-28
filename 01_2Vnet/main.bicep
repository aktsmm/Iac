param location string
param vnetAName string
param vnetAAddressPrefix string
param subnetAName string
param subnetAAddressPrefix string
param vmUbuntuHubName string
param vmWin2019OnpName string
param vmSize string
param adminUsername string

@secure()
param adminPassword string

param osDiskStorageType string
param vnetBName string
param vnetBAddressPrefix string
param subnetBName string
param subnetBAddressPrefix string
param nsgNameA string
param nsgNameB string

module networkModuleA 'NW.bicep' = {
  name: 'networkModuleA'
  params: {
    nsgName: nsgNameA
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
    nsgName: nsgNameB
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
    vmName: vmUbuntuHubName
    vmSize: vmSize
    osImageOffer: '0001-com-ubuntu-minimal-focal'
    osImagePublisher: 'Canonical'
    osImageSku: 'minimal-20_04-lts'
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskStorageType: osDiskStorageType
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
    vmName: vmWin2019OnpName
    vmSize: vmSize
    osImageOffer: 'WindowsServer'
    osImagePublisher: 'MicrosoftWindowsServer'
    osImageSku: '2019-Datacenter'
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskStorageType: osDiskStorageType
    subnetId: networkModuleB.outputs.subnetId
  }
  dependsOn: [
    networkModuleB
  ]
}
