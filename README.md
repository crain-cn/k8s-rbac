# k8s-rbac
用于k8s签发签名，并生成sa用户脚本。

# 准备工作
需要安装cfssl

macOS安装
```bash
brew install cfssl
```

CentOS安装
```bash
yum install cfssl
```

ubuntu安装
```bash
apt-get install golang-cfss
```

命令行安装
```bash
curl -s -L -o /bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -s -L -o /bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
curl -s -L -o /bin/cfssl-certinfo https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x /bin/cfssl*
```
