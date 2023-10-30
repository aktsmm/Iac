## 02_2Vnet-3VM： 2つの Vnet をつかう検証環境作成用に作りました
 
bicepで書いてそれを[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json) 


するためにARM-Template(Json)にコンパイル(main.jaon)しました。
パラメーターファイルは parameters.json

ざっくりというと、、、
+ 独立した Vnet を2つ作ります。
+ それぞれにWindowsとUbuntu、Ubuntuがデプロイされます。
+ Vnet 間はつながってません。
+ Vnet間をつなげるには 別途VnetPeeringなり、VPNが必要。


大体のリソース名はパラメーターファイルで変えられます。
Public IPもついてます。

イメージ図はこんな感じ。
![2023-10-30_17h18_21](https://github.com/aktsmm/Iac/assets/71251920/2388c3f4-bc6e-4670-a097-68ee180555f7)

## Deploy to Azure
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json) 



## べた書きしてる(パラメーター指定できない値)
### VM-A / Ubuntu
    vmSize: 'Standard_B2ms'
    osImageOffer: '0001-com-ubuntu-minimal-focal'
    osImagePublisher: 'Canonical'
    osImageSku: 'minimal-20_04-lts'
    osDiskStorageType:'StandardSSD_LRS'
### VM-B とVM-C /Windows
    vmSize: 'Standard_B2ms'
    osImageOffer: 'WindowsServer'
    osImagePublisher: 'MicrosoftWindowsServer'
    osImageSku: '2019-Datacenter'
    osDiskStorageType: 'StandardSSD_LRS'

## パラメーター
デプロイするときは[パラメーターファイル](https://github.com/aktsmm/Iac/blob/main/01_2Vnet-2VM/parameters.json)をコピーして、適宜編集して貼り付けると楽だと思います。
![image](https://github.com/aktsmm/Iac/assets/71251920/9b03ffce-273d-42ee-bb2d-f552eace5d36)
