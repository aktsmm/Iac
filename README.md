# Iac
しばらくbicep とARM-template(json) メインに基本的に自分用　
+ 使用は自己責任でお願いします


## 01_2Vnet-2VM： 2つの Vnet をつかうシンプルな検証環境作成用に

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json)

独立した Vnet を2つ、またVMを2つ作ります。
イメージ図はこんな感じ。(Azure のリソースVisualizer機能)
Vnet 間はつながってません。別途VnetPeeringなり、S2SVPNが必要。
Public IPもついてます。片方のVnetはWindows Server 2019 、もう片方は Ubuntu がデプロイされます。
![2023-10-31_02h25_24](https://github.com/aktsmm/Iac/assets/71251920/4f68b045-f6a3-41fb-8e81-41a82b61523f)

## 02_2Vnet-3VM： 2つの Vnet をつかうシンプルな検証環境作成用に
↑にWindows VMを1つ増やしました

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json)

![2023-10-31_02h23_14](https://github.com/aktsmm/Iac/assets/71251920/f2fc56e0-1933-4b7d-b44c-574f4dbef4f7)


## 03_bas-peer:  2Vnet、3VM 、加えてVnet Peering、Azure Bastion
Bastion入ってるのでデプロイに時間がかかります

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F03_bas-peer%2Fmain.json)

![2023-10-31_02h03_39](https://github.com/aktsmm/Iac/assets/71251920/04bff503-e773-4ceb-a64f-12dd17fb68bd)



## 04_Hub-Spoke-on： 3つの Vnetをデプロイし、Hub-Spoke間にVnet peering ,HubにBastion、それぞれのVnetにVMをデプロイします。
03を改良し、Onpreに見立てた Vnet を作るものBastion入ってるのでデプロイに時間がかかります

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F04_HUb-Spoke-Onp%2Fmain.json)

![2023-11-01_12h23_49](https://github.com/aktsmm/Iac/assets/71251920/24b13e42-589b-4ebe-bd7d-330ada032869)

## 05_SingleVnet-vpngw： 1つの Vnetをデプロイし、VPNGWをデプロイします。超シンプル
 
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F05_SingleVnet-vpngw%2Fbasic_vpngw_1file.json) 

イメージ図はこんな感じ。

![2023-11-12_00h47_27](https://github.com/aktsmm/Iac/assets/71251920/947fadac-2e3a-4821-bedd-600e0b7927d8)


## 06_hub-spoke_vpngw-onp： 04のHubVnetにVPNGWをデプロイ
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F06_hub_vpngw-spoke-onp%2Fmain.json)


イメージ図はこんな感じ。
![2023-11-12_01h58_49](https://github.com/aktsmm/Iac/assets/71251920/a24bf84d-7eef-4b1f-9335-5f49ef31230d)



## 07_1Vnet-2VM： 1つの Vnet をつかうシンプルな検証環境作成用に
 [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F07_1Vnet-2VM%2Fmain.json)

+ 独立した Vnet を１つ作ります。
+ それぞれにWindowsとUbuntu がデプロイされます。
+ Public IPもついてます
 ![2023-11-13_21h57_11](https://github.com/aktsmm/Iac/assets/71251920/f6844d85-5a79-4073-a25e-8c9697314f4d)


## 08_1Vnet-1VM-NATGW
### Bicep の概要  
   
このBicepファイルは、Azureで仮想ネットワーク、サブネット、仮想マシン、NATゲートウェイ、およびbastionを作成するために使用できます。このテンプレートには、場所、仮想ネットワーク名、サブネット名、アドレスプレフィックス、仮想マシン名、管理者の資格情報、NATゲートウェイ名、バスチオンホスト名、およびそれらに関連するリソースなどのパラメータが含まれています。  
このテンプレートは、仮想マシンへの安全なリモートアクセスを有効にするために、バスチオンホストを使用して仮想マシンに接続します。このテンプレートを使用すると、ユーザーは手動でこれらのリソースを作成する必要がなくなります。  


## 09_1Vnet-1VM-AZFW
###  Bicep の概要  
   このテンプレートは、Azure上に仮想ネットワーク、仮想マシン、Bastionホスト、およびAzure Firewallを作成するためのものです。  

## 10_1Vnet-1VM-ELB
###  Bicep の概要  
 このテンプレートは、Azure上に仮想ネットワーク、仮想マシン、Azure Bastion、およびLoad Balancerを作成するためのものです。  
 
 


## おまけ：Deploy to Azure Bottun の作り方
大まかにGithub にソースを上げてURL取得、加工してリンク作成です。
+ https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/templates/deploy-to-azure-button
Gitに上げてるjsonファイルを使うときは、rawでURLをとってURLを変換する必要がある、PowerShellを使って下記でエンコードしてリンクをつくる

```PowerShell
$url = "https://raw.githubusercontent.com/aktsmm/Iac/main/03_bas-peer/main.json"
[uri]::EscapeDataString($url)
$: https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F03_bas-peer%2Fmain.json
```
```
https://portal.azure.com/#create/Microsoft.Template/uri/<上記で取得したエンコードしたURL文字列>
```
でリンクをつくります。

+ マークダウンで書くときはこんな感じでよくある [Deploy to Azure] ボタンができます。
下記の **""https://portal.azure.com/#create/Microsoft.Template/uri/""** 以降に上記で作ったリンクを挿入します。
+ 例
```
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json)
``````

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json)
