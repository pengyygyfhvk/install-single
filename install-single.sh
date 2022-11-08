#!/bin/bash
ip="192.168.1.3"
domain=""

binaryPackage="./package"
install_home="/data"
installDocker(){
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在安装docker>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
tar -zxf  $binaryPackage/docker-20.10.8.tgz -C ./
cp ./docker/* /usr/bin/
       
echo "[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target
 
[Service]
Type=notify 
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
 
[Install]
WantedBy=multi-user.targe " > /usr/lib/systemd/system/docker.service
systemctl start docker
systemctl enable docker
docker info
systemctl status docker 
}

installES(){
 mkdir /data
 sed -i '$a es soft nofile 65536 \n es hard nofile 65536 \n es soft nproc 4096  \n es hard nproc 4096' /etc/security/limits.conf
 sed -i '$a es          soft    nproc     4096 \n root       soft    nproc     unlimited' /etc/security/limits.d/20-nproc.conf
 sed -i '$a vm.max_map_count = 655360' /etc/sysctl.conf
 sed -i '$a net.ipv4.ip_forward=1'    /etc/sysctl.conf
 systemctl restart network
 sysctl -p
adduser  es
tar -zxf $binaryPackage/es.tar.gz -C $install_home
chown -R es:es $install_home/es/  
su es -c "$install_home/es/elasticsearch-7.8.0/bin/elasticsearch -d"

}
installOpenJDK(){
 tar -zxf $binaryPackage/openjdk-17.0.2_linux-x64_bin.tar.gz -C /data/
    echo 'export JAVA_HOME=/data/jdk-17.0.2
    export PATH=$JAVA_HOME/bin:$PATH ' >> /etc/profile
    source /etc/profile
    javac 

}
installRedis(){
    docker load -i $binaryPackage/redis\:latest
    mkdir -p /data/redis
    cp $binaryPackage/redis.conf /data/redis/
    docker run -d --name redis -p 6379:6379  -v /data/redis/redis.conf:/usr/local/etc/redis/redis.conf redis --requirepass "yunst@2022"

}
installKafka(){
    docker load -i $binaryPackage/zookeeper\:latest
    docker run -d --name zookeeper -p 2181:2181 -t wurstmeister/zookeeper
    docker load -i $binaryPackage/kafka\:2.12-2.3.1
    docker run -d --name kafka -p 9092:9092 -v /data/sdc/kafka/logs:/opt/kafka/logs -v /data/sdc/kafka/kafka-logs:/kafka/kafka-logs -v /etc/localtime:/etc/localtime:ro -e KAFKA_BROKER_ID=0 -e KAFKA_ZOOKEEPER_CONNECT=$ip:2181 -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://$ip:9092 -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 -e KAFKA_LOG_DIRS=/kafka/kafka-logs -t wurstmeister/kafka:2.12-2.3.1
}
installNginx(){
    sudo yum install -y yum-utils
    echo "[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/7/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/7/x86_64/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true" > /etc/yum.repos.d/nginx.repo
    yum install  -y nginx
    mv  /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.bak
    mkdir  -p /data/www/qv-admin/
    cp -r ./nginx/dist /data/www/qv-admin/
    cp ./nginx/index.conf /etc/nginx/conf.d/
    cp  -r ./nginx/sslkey /etc/nginx/
    sed -i "3a       server_name ${domain}" /etc/nginx/conf.d/index.conf
    nginx -t
    nginx

}
isInstall(){
    softArray=( java nginx docker )
    for element in ${softArray[@]}
    #也可以写成for element in ${array[*]}
    do
    echo $element
    if ! type $element >/dev/null 2>&1;then
        echo "❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌${element}安装失败 ❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌"
        exit 8
    else
        echo "✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️ ${element}安装成功 ✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️"
    fi
    done

    #等待30秒
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>[正在启动elasticsearch]>>>>>>>>>>>>>>>>>>>>>>>>>"
    sleep 30
    echo "✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️ 启动完成 ✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️"

    ProcNumber=$(ps -ef |grep -w elasticsearch|wc -l)
    if [ ${ProcNumber} -le 1 ];then
    echo "❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌ elasticsearch安装失败 ❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌"
    exit 8
    else
    echo "✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️ elasticsearch安装成功 ✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️"
    # curl -XPUT  -u elastic:yunst@2022 -H "Content-Type:application/json" -d '{"persistent":{"cluster":{"max_shards_per_node":10000}}}' 'http://127.0.0.1:9200/_cluster/settings'
    fi
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>[正在启动java服务]>>>>>>>>>>>>>>>>>>>>>>>>>"
    startServer
    sleep 30
    echo "✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️ java启动完成 ✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️✌️"

}
startServer(){
    paramRedis="--spring.redis.host=${ip} --spring.redis.port=6379 --spring.redis.password=yunst@2022 --spring.redis.pool.enabled=true"
        paramEs="--spring.elasticsearch.uris=${ip}:9200 --spring.elasticsearch.password=yunst@2022"
        paramKafka="--spring.kafka.bootstrap-servers=${ip}:9092"
        #echo "java -server -Xms4g -Xmx8g -Djava.library.path=. $paramRedis $paramEs $paramKafka $paramDomain  -jar archiving.jar "
        nohup java -server -Xms4g -Xmx8g -Djava.library.path=.  -jar xxx.jar  $paramRedis $paramEs $paramKafka   &
}
stopJava(){
    
    tokill=`ps -ef | grep java | grep xxx.jar | awk '{print $2}'`
    kill -9 $tokill
    echo "java服务已经停止运行"
}
installKibana(){
    tar -zxf $binaryPackage/kibana-7.8.0-linux-x86_64.tar.gz -C $install_home
echo "server.name: kibana
server.host: \"0.0.0.0\"
elasticsearch.hosts: [\"http://${ip}:9200\"]
monitoring.ui.container.elasticsearch.enabled: true
elasticsearch.username: \"elastic\"
elasticsearch.password: \"yunst@2022\"
i18n.locale: \"zh-CN\"" > $install_home/kibana-7.8.0-linux-x86_64/config/kibana.yml
nohup $install_home/kibana-7.8.0-linux-x86_64/bin/kibana --allow-root &
}
downPackage(){
   wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/docker-20.10.8.tgz -P ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/es.tar.gz ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/filebeat-7.8.0-linux-x86_64.tar.gz ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/redis.conf ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/zookeeper%3Alatest ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/openjdk-17.0.2_linux-x64_bin.tar.gz ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/kafka%3A2.12-2.3.1 ./package/
    wget https://xy-1257362739.cos.ap-nanjing.myqcloud.com/package/kibana-7.8.0-linux-x86_64.tar.gz ./package/
}
#安装docker
#installDocker
#安装es
#installES
#安装jdk
#installOpenJDK
#安装kafka
#installKafka
#安装redis
#installRedis
#安装nginx
initMain(){
    case $1 in
    docker)   echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在安装docker>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装docker
        installDocker
    ;;
    es)       echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在安装es>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装es
        installES
    ;;
    jdk)      echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在安装jdk>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装jdk
        installOpenJDK
    ;;
    kafka)    echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在安装kafka>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装kafka
        installKafka
    ;;
    redis)    echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在安装redis>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装redis
        installRedis
    ;;
    all)    echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>一件安装所有中间件>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装docker
        installDocker
        #安装es
        installES
        #安装jdk
        installOpenJDK
        #安装kafka
        installKafka
        #安装redis
        installRedis
        #安装nginx
        installNginx
        #判断是否安装成功
        isInstall
    

    ;;
    java)    echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在启动java服务>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #启动java服务
        startServer

    ;;
     init)    echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在初始化数据>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        curl localhost:8080/api/init -X POST -d @data.json --header "Content-Type: application/json"
        curl localhost:8080/api/setting/validSetting -XPOST  -d @data1.json  --header "Content-Type: application/json"
    ;;
     nginx)   echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在安装nginx>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装nginx
        installNginx
    ;;
    stop)   echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在停止java服务>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装nginx
        stopJava
    ;;
    kibana)   echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在安装kibana>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装kibana
        installKibana
    ;;
     download)   echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>正在下载安装包>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
        #安装kibana
        downPackage
    ;;
esac
}

initMain $1
