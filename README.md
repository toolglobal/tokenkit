# token kit
ORC20代币发行工具。为了兼容OLO Swap，token 小数位使用8位。

## 部署合约
发行1亿个ABC
```
$ ./tokenkit.exe deploy --key=私钥 --name="ABC Token" --symbol=ABC --supply=100000000 --api=https://olo.ibdt.tech
hash:0x3bf1207709c513d76530d36269595c264d17fb73e0710bac922c00b0e138f762 contract:0xc101f8a08D95c0c0A75931aFb3D09Fb38E4209f5 gasUsed:1978959 err:<nil>
```

## 查询余额
```shell
$ ./tokenkit.exe balanceOf --token=0xc101f8a08D95c0c0A75931aFb3D09Fb38E4209f5 --address=0x0F508F143E77b39F8e20DD9d2C1e515f0f527D9F --api=https://olo.ibdt.tech
balance:10000000000000000 err:<nil>
```

## 增发
增发1个ABC
```shell
$ ./tokenkit.exe issue --amount=1 --key=私钥 --token=0xc101f8a08D95c0c0A75931aFb3D09Fb38E4209f5
hash:0x5267b36dbe9b15aaf4248daa35adfb888f8f6b1bf365fb722880e22d8b8ec52f gasUsed:39099 err:<nil>
```

## 燃烧
燃烧一个ABC
```shell
$ ./tokenkit.exe redeem --amount=1 --key=私钥 --token=0xc101f8a08D95c0c0A75931aFb3D09Fb38E4209f5
hash:0xe07ba511bd6c5351ba4d583bb896c90629e5d733269c5140e6987ee008bfd23e gasUsed:39109 err:<nil>
```