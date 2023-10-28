## 01_2Vnet： 検証環境のベース環境デプロイ用に作りました。

ざっくりというと 独立した Vnet を2つ作ります。

それぞれにWindowsとUbuntuがデプロイされます。

イメージ図はこんな感じ。
![image](https://github.com/aktsmm/Iac/assets/71251920/be8b2d22-f031-4076-9c0c-8b8ca5e5e215)

学習・検証環境のベース環境デプロイ用に作りました。
Vnet 間はつながってません。
Vnet間をつなげるには 別途VnetPeeringなり、VPNが必要。

大体のリソース名はパラメーターファイルで変えられます。
Public IPもついてます。片方のVnetはWindows Server 2019 、もう片方は Ubuntu がデプロイされます。

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet%2Fmain.json)



## べた書きしてる(パラメーター指定できない値)
### VM-A / Ubuntu
    vmSize: 'Standard_B2ms'
    osImageOffer: '0001-com-ubuntu-minimal-focal'
    osImagePublisher: 'Canonical'
    osImageSku: 'minimal-20_04-lts'
    osDiskStorageType:'StandardSSD_LRS'
### VM-B /Windows
    vmSize: 'Standard_B2ms'
    osImageOffer: 'WindowsServer'
    osImagePublisher: 'MicrosoftWindowsServer'
    osImageSku: '2019-Datacenter'
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskStorageType: 'StandardSSD_LRS'

## パラメーター
デプロイするときは[パラメーターファイル](https://github.com/aktsmm/Iac/blob/main/01_2Vnet/parameters.json)をコピーして、適宜編集して貼り付けると楽だと思います。
![image](https://github.com/aktsmm/Iac/assets/71251920/9b03ffce-273d-42ee-bb2d-f552eace5d36)
