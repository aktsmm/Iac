## 01_2Vnet-2VM： 2つの Vnet をつかう検証環境作成用に

bicepで書いてそれを[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json){:target="_blank"}するためにARM-Template(Json)にコンパイル(main.jaon)しました。
パラメーターファイルは parameters.json

ざっくりというと、、、
+ 独立した Vnet を2つ作ります。
+ それぞれにWindowsとUbuntuがデプロイされます。
+ Vnet 間はつながってません。
+ Vnet間をつなげるには 別途VnetPeeringなり、VPNが必要。


大体のリソース名はパラメーターファイルで変えられます。
Public IPもついてます。片方のVnetはWindows Server 2019 、もう片方は Ubuntu がデプロイされます。

イメージ図はこんな感じ。
![2023-10-31_02h25_24](https://github.com/aktsmm/Iac/assets/71251920/4f68b045-f6a3-41fb-8e81-41a82b61523f)



## Deploy to Azure
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json)



## べた書きしてる(パラメーター指定できない値)
### VM-A / Ubuntu
    vmSize: 'Standard_B2s'
    osImageOffer: '0001-com-ubuntu-server-focal'
    osImagePublisher: 'Canonical'
    osImageSku: '20_04-lts'
    osDiskStorageType:'StandardSSD_LRS'
### VM-B /Windows
    vmSize: 'Standard_B2s'
    osImageOffer: 'WindowsServer'
    osImagePublisher: 'MicrosoftWindowsServer'
    osImageSku: '2019-Datacenter'
    osDiskStorageType: 'StandardSSD_LRS'

## パラメーター
デプロイするときは[パラメーターファイル](https://github.com/aktsmm/Iac/blob/main/01_2Vnet/parameters.json)をコピーして、適宜編集して貼り付けると楽だと思います。
+ **パスワード**パラメーターは必ず適切な値を入れる必要があります
![2023-10-30_17h03_57](https://github.com/aktsmm/Iac/assets/71251920/044b9c29-d358-4b5b-9884-c81157fd7961)



![image](https://github.com/aktsmm/Iac/assets/71251920/9b03ffce-273d-42ee-bb2d-f552eace5d36)
