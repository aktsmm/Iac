# Iac
しばらくbicep とARM-template(json) メイン

使用は自己責任で


## 01_2Vnet-2VM： 検証環境のベース環境デプロイ用に作りました。

独立した Vnet を2つ、またVMを2つ作ります。
イメージ図はこんな感じ。(Azure のリソースVisualizer機能)
![image](https://github.com/aktsmm/Iac/assets/71251920/ede6ff89-770a-4992-a660-b4ea40f47894)



学習検証環境のベース環境デプロイ用に作りました。
Vnet 間はつながってません。別途VnetPeeringなり、S2SVPNが必要。
リソース名はパラメーターファイルで変えられます。
Public IPもついてます。片方のVnetはWindows Server 2019 、もう片方は Ubuntu がデプロイされます。


[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet-2VM%2Fmain.json)
## Deploy to Azure Bottun の作り方
大まかにGithub にソースを上げてURL取得、加工してリンク作成です。
https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/templates/deploy-to-azure-button
