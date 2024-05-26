param location string = resourceGroup().location  
param vnetName string  
param subnetName string  
param firewallSubnetName string = 'AzureFirewallSubnet'  
param vnetAddressPrefix string  
param subnetAddressPrefix string  
param bastionSubnetAddressPrefix string  
param firewallSubnetAddressPrefix string  
param vmName string  
param adminUsername string  
@secure()  
param adminPassword string  
param firewallName string  
param firewallPublicIPName string  
param bastionName string  
param bastionPublicIPName string  
param bastionSubnetName string  
  
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

  
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {  
  parent: vnet  
  name: subnetName  
}  
  
resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {  
  name: '${vmName}-nic'  
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
        }  
      }  
    ]  
  }  
}  
  
resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {  
  name: vmName  
  location: location  
  dependsOn: [  
    nic  
  ]  
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
      computerName: vmName  
      adminUsername: adminUsername  
      adminPassword: adminPassword  
    }  
    networkProfile: {  
      networkInterfaces: [  
        {  
          id: nic.id  
        }  
      ]  
    }  
  }  
}  
  
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {  
  parent: vnet  
  name: bastionSubnetName  
}  
  
resource bastion 'Microsoft.Network/bastionHosts@2022-05-01' = {  
  name: bastionName  
  location: location  
  properties: {  
    ipConfigurations: [  
      {  
        name: 'bastionIpConfig'  
        properties: {  
          subnet: {  
            id: bastionSubnet.id  
          }  
          publicIPAddress: {  
            id: bastionPublicIP.id  
          }  
        }  
      }  
    ]  
  }  
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
  
resource routeTableAssociation 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {  
  name: subnetName  
  parent: vnet  
  properties: {  
    addressPrefix: subnetAddressPrefix  
    routeTable: {  
      id: routeTable.id  
    }  
  }  
}  
