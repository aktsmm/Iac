## 06_hub-spoke_vpngw-onp： 04のHubVnetにVPNGWをデプロイしたものです。
bicepで書いてそれを[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F06_hub_vpngw-spoke-onp%2Fmain.json) 
するためにARM-Template(Json)にコンパイル(main.jaon)しました。
パラメーターファイルは parameters.json

ざっくりというと、、、
+ 独立した Vnet を3つ作ります。
+ それぞれにWindowsとUbuntu、Ubuntuがデプロイされます。
+ Hub-Spoke Vnet 間は VnetPeering でつながってます。
+ Hub Vnet には VPNGWがついています
+ Hub Vnet には Azure Bastion もついてます。(そのためデプロイに時間がかかる)
+ オンプレ相当の環境のVnetもデプロイしますが、HubVnetとはpeering,S2S-VPN等していません。
大体のリソース名はパラメーターファイルで変えられます。VPNGWのSKUは今のところBasicもデプロイできます。(P2Sの検証をする場合に使えます)
Public IPもついてます。

イメージ図はこんな感じ。
![2023-11-12_01h58_49](https://github.com/aktsmm/Iac/assets/71251920/a24bf84d-7eef-4b1f-9335-5f49ef31230d)

## Deploy to Azure
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F06_hub_vpngw-spoke-onp%2Fmain.json) 

## べた書きしてる(パラメーター指定できない値)
### VM-A / Ubuntu
    vmSize: 'Standard_B2s'
    osImageOffer: '0001-com-ubuntu-server-focal'
    osImagePublisher: 'Canonical'
    osImageSku: '20_04-lts"'
    osDiskStorageType:'StandardSSD_LRS'
### VM-B とVM-C /Windows
    vmSize: 'Standard_B2s'
    osImageOffer: 'WindowsServer'
    osImagePublisher: 'MicrosoftWindowsServer'
    osImageSku: '2019-Datacenter'
    osDiskStorageType: 'StandardSSD_LRS'
## 他
 vpngwsku ："VpnGw1" とか "basic" とか入れていければいいなと思っています。
 検証であれば大きな違いとしては 課金があるので基本P2S の時は basic 、s2sが必要な時はVpnGw1 とかでいいかなと。
## パラメーター
デプロイするときは[パラメーターファイル](https://github.com/aktsmm/Iac/blob/main/06_hub_vpngw-spoke-onp/parameters.json)をコピーして、password部分など適宜編集して貼り付けると楽だと思います。
![image](https://github.com/aktsmm/Iac/assets/71251920/9b03ffce-273d-42ee-bb2d-f552eace5d36)
