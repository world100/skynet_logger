#!/bin/bash
#开发环境配置
cd server
export LOBSTER_HOST_IP='127.0.0.1'

export LOBSTER_REDIS_HOST='127.0.0.1'
export LOBSTER_REDIS_PORT=6379
export LOBSTER_REDIS_PWD='xxx'

export LOBSTER_MYSQL_HOST='127.0.0.1'
export LOBSTER_MYSQL_PORT=3306
export LOBSTER_MYSQL_USER='root'
export LOBSTER_MYSQL_DB_GAME='xxx'
export LOBSTER_MYSQL_PWD='xxx'


./run.sh loggerserver &
sleep 1
./run.sh gateserver &
