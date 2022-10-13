# 在 Ubuntu 18.04 部署redash 的docker 版本的脚本

这个项目是基于官方redash的部署脚本进行修改的一个redash部署脚本


## 部署

一般在读写权限的目录复制下面的脚本到控制台执行即可；如果想修改其中docker-compose 的配置，直接clone 之后修改就可以了

```shell script
echo "下载执行脚本和docker-compose配置文件"
git clone https://github.com/KANLON/setup.git 
cd setup
echo "开始执行，如果要异步执行，可以使用 nohup ./setup.sh & 这样来执行"
./setup.sh
```

注意： 需要保证执行的时候在该项目的根目录下，不然获取不到对应配置文件，即 `./setup.sh` 这个命令，不能使用完整路径执行，例如：`/data/service/setup.sh` 这样去执行

## 改动点
主要改动有以下几点：
1. 修改docker-compose.yml 默认映射主机的端口的80 修改为 8050
2. 修改部署脚本 `setup.sh` 中获取 docker-compose.yml 配置文件的方式从 github 获取，修改为从当前执行目录的 `./data/docker-compose.yml` 中获取(即修改使用执行命令项目的中的配置文件)
3. export COMPOSE_FILE=${REDASH_BASE_PATH}/docker-compose.yml 变量中 之前固定的路径 /opt/redash 路径，修改为从前面定义的变量中获取 ${REDASH_BASE_PATH}，统一路径
4. 增加docker swarm 版本 的docker-compose的配置文件  



## 文件相关说明
1.  `docker-compose.yml`  这里启动会，占用了服务器的 5000 和 8050 端口； 端口配置8050:80,表示主机8050 映射到容器80端口

2. `docker-compose-docker-swarm.yml`
    
    2.1. 这个为docker swarm 版本的 docker-compose 配置文件，如果服务器有上docker swarm 集群，则直接用这个配置文件启动即可
    
    2.2. 启动命令为  sudo docker stack deploy -c docker-compose-docker-swarm.yml --with-registry-auth redash-service
    
    2.3. 执行完docker 容器之后的，进入 redash server 容器中，到 /app 目录下，执行 ./manage.py database create_tables 创建表。




## 原 redash 部署的脚本相关说明

Setup script for Redash with Docker on Ubuntu 18.04.


用了docker  和  Docker Compose  来部署和管理


* `setup.sh` 这个是部署脚本
* `docker-compose.yml` 这个是 Docker Compose 的设置文件
