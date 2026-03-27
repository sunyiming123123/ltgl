#!/bin/bash

echo "等待 SQL Server 启动..."
sleep 20

echo "运行数据库迁移..."
docker exec -it glxt-api dotnet ef database update

echo "数据库初始化完成！"
