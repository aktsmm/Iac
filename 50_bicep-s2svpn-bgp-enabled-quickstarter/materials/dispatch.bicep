var location = 'japaneast'

// Create default NSG
module defaultNSG './modules/nsg.bicep' = {
  name: 'NetworkSecurityGroup'
  params:{
    location: location
    name: 'default-nsg'  
  }
}

// Create Cloud&Onp VNet
module createVNets './modules/VNet.bicep' = {
  name: 'vnet-cloud'
  params:{
    location: location
    nsgId: defaultNSG.outputs.nsgId
  }
}

// Create Cloud VPNGW PIP
module  vpngwCloudPIP './modules/publicIP.bicep' = {
  name: 'pip-cloud-gw'
  params:{
    location: location
    suffix: 'cloud-gw'  
  }
}

// Create ONP VPNGW PIP
module  vpngwOnpPIP './modules/publicIP.bicep' = {
  name: 'pip-onp-gw'
  params:{
    location: location
    suffix: 'onp-gw'  
  }
}
