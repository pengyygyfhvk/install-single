# 自动化安装部署说明

### 首先下载到本地或者部署服务修改single-install.sh文件，修改为内网ip地址
- [ ] ip=""

### 在线下载安装包，如果没有网络下载安装包到package目录即可。
``` 
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/docker-20.10.8.tgz -P ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/es.tar.gz ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/filebeat-7.8.0-linux-x86_64.tar.gz ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/redis.conf ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/zookeeper%3Alatest ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/openjdk-17.0.2_linux-x64_bin.tar.gz ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/kafka%3A2.12-2.3.1 ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/kibana-7.8.0-linux-x86_64.tar.gz ./package/
```

### 下载安装包
``` 
sh install-single.sh download
```


### 安装docker 
``` 
sh install-single.sh docker 
```



### 安装elasticsaerch 
``` 
sh install-single.sh es
``` 

### 安装redis 
``` 
sh install-single.sh redis
``` 

### 安装kafaka
``` 
sh install-single.sh kafaka
``` 

### 安装jdk
``` 
sh install-single.sh jdk
``` 

### 安装kibana
``` 
sh install-single.sh kibana
``` 




