# Iac
しばらくbicepメイン

使用は自己責任で


## 01_2Vnet： 検証環境のベース環境デプロイ用に作りました。

独立した Vnet を2つ作ります。
イメージ図はこんな感じ。
![image](https://github.com/aktsmm/Iac/assets/71251920/be8b2d22-f031-4076-9c0c-8b8ca5e5e215)

学習検証環境のベース環境デプロイ用に作りました。
Vnet 間はつながってません。別途VnetPeeringなり、S2SVPNが必要。
リソース名はパラメーターファイルで変えられます。
Public IPもついてます。片方のVnetはWindows Server 2019 、もう片方は Ubuntu がデプロイされます。


[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faktsmm%2FIac%2Fmain%2F01_2Vnet%2Fmain.json)

