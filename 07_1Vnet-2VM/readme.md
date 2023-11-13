## 07_1Vnet-2VM： 1つの Vnet をつかうシンプルな検証環境作成用に
 
bicepで書いてそれを[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json) 


するためにARM-Template(Json)にコンパイル(main.jaon)しました。
パラメーターファイルは parameters.json

ざっくりというと、、、
+ 独立した Vnet を１つ作ります。
+ それぞれにWindowsとUbuntu がデプロイされます。

大体のリソース名はパラメーターファイルで変えられます。
Public IPもついてます。

イメージ図はこんな感じ。
![2023-11-13_21h57_11](https://github.com/aktsmm/Iac/assets/71251920/f6844d85-5a79-4073-a25e-8c9697314f4d)


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

![2023-10-30_23h40_47](https://github.com/aktsmm/Iac/assets/71251920/af5252a5-88b3-44ec-b05f-0989b12f64a2)


![image](https://github.com/aktsmm/Iac/assets/71251920/9b03ffce-273d-42ee-bb2d-f552eace5d36)
