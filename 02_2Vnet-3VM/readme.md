## 02_2Vnet-3VM： 2つの Vnet をつかうシンプルな検証環境作成用に
 
bicepで書いてそれを[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json) {:target="_blank"}


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
![2023-10-31_02h23_14](https://github.com/aktsmm/Iac/assets/71251920/f2fc56e0-1933-4b7d-b44c-574f4dbef4f7)


## Deploy to Azure
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json) {:target="_blank"}



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
デプロイするときは[パラメーターファイル](https://github.com/aktsmm/Iac/blob/main/01_2Vnet-2VM/parameters.json)をコピーして、適宜編集して貼り付けると楽だと思います。

![2023-10-30_23h40_47](https://github.com/aktsmm/Iac/assets/71251920/af5252a5-88b3-44ec-b05f-0989b12f64a2)


![image](https://github.com/aktsmm/Iac/assets/71251920/9b03ffce-273d-42ee-bb2d-f552eace5d36)
