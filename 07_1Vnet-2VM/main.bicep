param location string
param VnetAName string

param vnetAAddressPrefix string 
param subnetAName string ='${VnetAName}-Subnet'
param subnetAAddressPrefix string
param nsgAName string='${VnetAName}-nsg'

param vmAUbuntuName string='${VnetAName}-Ubu'
param vmBWin2019Name string='${VnetAName}-Win'
param adminUsername string
@secure()
param adminPassword string


module networkModuleA 'NW.bicep' = {
  name: 'networkModuleA'
  params: {
    nsgName: nsgAName
    location: location
    vnetName: VnetAName
    vnetAddressPrefix: vnetAAddressPrefix
    subnetName: subnetAName
    subnetAddressPrefix: subnetAAddressPrefix
  }
}


module vmModuleA_Ubuntu 'VM.bicep' = {
  name: 'vmModuleA_Ubuntu'
  params: {
    location: location
    vmName: vmAUbuntuName
    vmSize: 'Standard_B2ms'
    osImageOffer: '0001-com-ubuntu-server-focal'
    osImagePublisher: 'Canonical'
    osImageSku: '20_04-lts'
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

