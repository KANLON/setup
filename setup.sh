#!/usr/bin/env bash
# This script setups dockerized Redash on Ubuntu 18.04.
set -eu

REDASH_BASE_PATH=/opt/redash

install_docker(){
    # Install Docker
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get -qqy update
    DEBIAN_FRONTEND=noninteractive sudo -E apt-get -qqy -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade 
    sudo apt-get -yy install apt-transport-https ca-certificates curl software-properties-common wget pwgen
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update && sudo apt-get -y install docker-ce

    # Install Docker Compose
    sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Allow current user to run Docker commands
    sudo usermod -aG docker $USER
}

create_directories() {
    if [[ ! -e $REDASH_BASE_PATH ]]; then
        sudo mkdir -p $REDASH_BASE_PATH
        sudo chown $USER:$USER $REDASH_BASE_PATH
    fi

    if [[ ! -e $REDASH_BASE_PATH/postgres-data ]]; then
        mkdir $REDASH_BASE_PATH/postgres-data
    fi
}

create_config() {
    if [[ -e $REDASH_BASE_PATH/env ]]; then
        rm $REDASH_BASE_PATH/env
        touch $REDASH_BASE_PATH/env
    fi

    COOKIE_SECRET=$(pwgen -1s 32)
    SECRET_KEY=$(pwgen -1s 32)
    POSTGRES_PASSWORD=$(pwgen -1s 32)
    REDASH_DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@postgres/postgres"

    echo "PYTHONUNBUFFERED=0" >> $REDASH_BASE_PATH/env
    echo "REDASH_LOG_LEVEL=INFO" >> $REDASH_BASE_PATH/env
    echo "REDASH_REDIS_URL=redis://redis:6379/0" >> $REDASH_BASE_PATH/env
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> $REDASH_BASE_PATH/env
    echo "REDASH_COOKIE_SECRET=$COOKIE_SECRET" >> $REDASH_BASE_PATH/env
    echo "REDASH_SECRET_KEY=$SECRET_KEY" >> $REDASH_BASE_PATH/env
    echo "REDASH_DATABASE_URL=$REDASH_DATABASE_URL" >> $REDASH_BASE_PATH/env
}

setup_compose() {
    # wget https://raw.githubusercontent.com/getredash/setup/${GIT_BRANCH}/data/docker-compose.yml
    # 从git上下载docker-compose 修改为 获取该项目自身的docker-compose
    sudo /bin/cp -rf data/docker-compose.yml $REDASH_BASE_PATH/docker-compose.yml
    
    REQUESTED_CHANNEL=stable
    LATEST_VERSION=`curl -s "https://version.redash.io/api/releases?channel=$REQUESTED_CHANNEL"  | json_pp  | grep "docker_image" | head -n 1 | awk 'BEGIN{FS=":"}{print $3}' | awk 'BEGIN{FS="\""}{print $1}'`

    cd $REDASH_BASE_PATH
    GIT_BRANCH="${REDASH_BRANCH:-master}" # Default branch/version to master if not specified in REDASH_BRANCH env var
    sed -ri "s/image: redash\/redash:([A-Za-z0-9.-]*)/image: redash\/redash:$LATEST_VERSION/" docker-compose.yml
    echo "export COMPOSE_PROJECT_NAME=redash" >> ~/.profile
    echo "export COMPOSE_FILE=${REDASH_BASE_PATH}/docker-compose.yml" >> ~/.profile
    export COMPOSE_PROJECT_NAME=redash
    export COMPOSE_FILE=${REDASH_BASE_PATH}/docker-compose.yml
    # 初始化redis 和 postgres 数据库
    sudo docker-compose run --rm server create_db
    # 启动容器
    sudo docker-compose up -d
}

# 安装docker 和 docker-compose，如果自己的机器上，这个已经安装了，则可以注释掉这个命令
install_docker
echo "安装完docker 和 docker-compose"
# 创建和授权数据目录
create_directories
echo "完成创建和授权数据目录"
# 创建配置文件
create_config
echo "完成创建配置文件"
# 实际启动 docker 容器和初始化数据库
setup_compose
echo "部署完成"
