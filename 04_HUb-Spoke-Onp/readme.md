## 04_Hub-Spoke-on： 3つの Vnetをデプロイし、Hub-Spoke間にVnet peering ,HubにBastion、それぞれのVnetにVMをデプロイします。
 
bicepで書いてそれを[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F04_HUb-Spoke-Onp%2Fmain.json)


するためにARM-Template(Json)にコンパイル(main.jaon)しました。
パラメーターファイルは parameters.json

ざっくりというと、、、
+ 独立した Vnet を3つ作ります。
+ それぞれにWindowsとUbuntu、Ubuntuがデプロイされます。
+ Vnet 間は VnetPeering でつながってます。
+ Azure Bastion もついてます。(そのためデプロイに時間がかかる)
+ オンプレ相当の環境のVnetもデプロイしますが、HubVnetとはpeering,S2S-VPN等していません。

大体のリソース名はパラメーターファイルで変えられます。
Public IPもついてます。

イメージ図はこんな感じ。
![2023-11-01_12h23_49](https://github.com/aktsmm/Iac/assets/71251920/24b13e42-589b-4ebe-bd7d-330ada032869)

## Deploy to Azure
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F04_HUb-Spoke-Onp%2Fmain.json)



## べた書きしてる(パラメーター指定できない値)
### VM-A / Ubuntu
    vmSize: 'Standard_B2s'
    osImageOffer: '0001-com-ubuntu-server-focal'
    osImagePublisher: 'Canonical'
    osImageSku: '20_04-lts'
    osDiskStorageType:'StandardSSD_LRS'
### VM-B とVM-C /Windows
    vmSize: 'Standard_B2s'
    osImageOffer: 'WindowsServer'
    osImagePublisher: 'MicrosoftWindowsServer'
    osImageSku: '2019-Datacenter'
    osDiskStorageType: 'StandardSSD_LRS'

## パラメーター
デプロイするときは[パラメーターファイル](https://github.com/aktsmm/Iac/blob/main/04_HUb-Spoke-Onp/parameters.json)をコピーして、password部分など適宜編集して貼り付けると楽だと思います。
![image](https://github.com/aktsmm/Iac/assets/71251920/9b03ffce-273d-42ee-bb2d-f552eace5d36)
