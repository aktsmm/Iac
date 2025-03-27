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

resource nsgRuleA80 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = {
  name: '${nsgAName}/Allow-HTTP-80'
  properties: {
    priority: 1000
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
  }
  dependsOn: [
    networkModuleA
  ]
}

resource nsgRuleA443 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = {
  name: '${nsgAName}/Allow-HTTPS-443'
  properties: {
    priority: 1001
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
  }
  dependsOn: [
    networkModuleA
  ]
}

resource nsgRuleA22 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = {
  name: '${nsgAName}/Allow-SSH-22'
  properties: {
    priority: 1002
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '22'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
  }
  dependsOn: [
    networkModuleA
  ]
}

resource nsgRuleB80 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = {
  name: '${nsgBName}/Allow-HTTP-80'
  properties: {
    priority: 1000
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
  }
  dependsOn: [
    networkModuleB
  ]
}

resource nsgRuleB443 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = {
  name: '${nsgBName}/Allow-HTTPS-443'
  properties: {
    priority: 1001
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
  }
  dependsOn: [
    networkModuleB
  ]
}

resource nsgRuleB3389 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = {
  name: '${nsgBName}/Allow-RDP-3389'
  properties: {
    priority: 1002
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '3389'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
  }
  dependsOn: [
    networkModuleB
  ]
}

module vmModuleA_Ubuntu 'VM.bicep' = {
  name: 'vmModuleA_Ubuntu'
  params: {
    location: location
    vmName: vmAUbuntuName
    vmSize: 'Standard_B2s'
    osImageOffer: '0001-com-ubuntu-server-focal'
    osImagePublisher: 'canonical'
    osImageSku: '20_04-lts'
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskStorageType:'StandardSSD_LRS'
    subnetId: networkModuleA.outputs.subnetId
  }
  dependsOn: [
    networkModuleA
    nsgRuleA80
    nsgRuleA443
    nsgRuleA22
  ]
}

module vmModuleB_Windows 'VM.bicep' = {
  name: 'vmModuleB_Windows'
  params: {
    location: location
    vmName: vmBWin2019Name
    vmSize: 'Standard_B2s'
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
    nsgRuleB80
    nsgRuleB443
    nsgRuleB3389
  ]
}

resource installApache 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: '${vmAUbuntuName}/installApache'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
      commandToExecute: 'sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* && sudo apt-get update -y && sudo apt-get install -y apache2 && sudo systemctl start apache2 && sudo systemctl enable apache2 && echo "Hi, this is Apache2 on $(hostname) by Apache2" | sudo tee /var/www/html/index.html'
    }
  }
  dependsOn: [
    vmModuleA_Ubuntu
  ]
}

resource installIIS 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: '${vmBWin2019Name}/installIIS'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
      commandToExecute: 'powershell -Command "Install-WindowsFeature -name Web-Server -IncludeManagementTools; $iisstart_path = Join-Path $Env:SystemDrive \'inetpub\\wwwroot\\iisstart.htm\'; Remove-Item $iisstart_path; Add-Content -Path $iisstart_path -Value \\"Hi, this is IIS on $Env:ComputerName\\""'
    }
  }
  dependsOn: [
    vmModuleB_Windows
  ]
}
