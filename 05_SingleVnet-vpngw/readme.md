## 05_SingleVnet-vpngw： 1つの Vnetをデプロイし、VPNGWをデプロイします。超シンプル
 
bicepで書いてそれを[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F04_HUb-Spoke-Onp%2Fmain.json) 


するためにARM-Template(Json)にコンパイル(main.jaon)しました。
パラメーターファイルは parameters.json

ざっくりというと、、、
+ 1つの Vnetをデプロイし、VPNGWをデプロイします。超シンプル

大体のリソース名はパラメーターファイルで変えられます。
Public IPもついてます。

イメージ図はこんな感じ。
![2023-11-12_00h47_27](https://github.com/aktsmm/Iac/assets/71251920/947fadac-2e3a-4821-bedd-600e0b7927d8)

## Deploy to Azure
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F04_HUb-Spoke-Onp%2Fmain.json) 


## パラメーター
>param location string// = 'japaneast'
param VnetName string //= 'Vnet-Hub'
param vpngwName string //= 'vpngw'
param publicIpName string = '${vpngwName}-pip'
param gatewaySubnetAddress string //= '10.0.100.0/24'
param VnetAddress string //= '10.0.0.0/16'

デプロイするときは[パラメーターファイル](https://github.com/aktsmm/Iac/blob/main/04_HUb-Spoke-Onp/parameters.json)をコピーして、password部分など適宜編集して貼り付けると楽だと思います。
![image](https://github.com/aktsmm/Iac/assets/71251920/9b03ffce-273d-42ee-bb2d-f552eace5d36)


