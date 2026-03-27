#!/bin/bash

# GLXT Docker 服务器部署脚本
# 使用方法: chmod +x deploy-server.sh && ./deploy-server.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}   GLXT Docker 服务器部署脚本${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 检查 Docker 是否安装
echo -e "${YELLOW}检查 Docker 环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ 错误: Docker 未安装${NC}"
    echo ""
    echo "请先安装 Docker:"
    echo "Ubuntu: curl -fsSL https://get.docker.com | sh"
    echo "或访问: https://docs.docker.com/engine/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker 已安装: $(docker --version)${NC}"

# 检查 Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose 未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker Compose 已安装: $(docker compose version)${NC}"

# 检查 docker-compose.yml 是否存在
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}✗ 错误: 找不到 docker-compose.yml 文件${NC}"
    echo "当前目录: $(pwd)"
    echo "请确保在项目目录下运行此脚本"
    exit 1
fi

echo -e "${GREEN}✓ 找到配置文件${NC}"
echo ""

# 显示菜单
echo -e "${CYAN}请选择操作:${NC}"
echo "1. 🚀 构建并启动服务"
echo "2. 🔄 重启服务"
echo "3. ⏹️  停止服务"
echo "4. 📋 查看日志"
echo "5. 📊 查看运行状态"
echo "6. 🔧 更新服务（拉取最新代码并重启）"
echo "7. 🧹 清理并重新部署"
echo "8. 💾 备份数据库"
echo "9. 🗑️  清理 Docker 资源"
echo ""

read -p "请输入选项 (1-9): " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}=====================================${NC}"
        echo -e "${YELLOW}   构建并启动服务${NC}"
        echo -e "${YELLOW}=====================================${NC}"
        echo ""

        # 停止现有服务
        echo -e "${YELLOW}停止现有服务...${NC}"
        docker compose down

        # 构建并启动
        echo -e "${YELLOW}构建镜像并启动服务...${NC}"
        docker compose up -d --build

        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}=====================================${NC}"
            echo -e "${GREEN}   ✓ 服务启动成功!${NC}"
            echo -e "${GREEN}=====================================${NC}"
            echo ""
            echo -e "${CYAN}服务状态:${NC}"
            docker compose ps
            echo ""
            echo -e "${CYAN}访问地址:${NC}"
            echo "  HTTP:  http://$(hostname -I | awk '{print $1}'):5000"
            echo "  本地:  http://localhost:5000"
            echo ""
            echo -e "${YELLOW}提示: 使用 'docker compose logs -f' 查看实时日志${NC}"
        else
            echo ""
            echo -e "${RED}✗ 服务启动失败${NC}"
            echo ""
            echo -e "${YELLOW}查看错误日志:${NC}"
            docker compose logs
        fi
        ;;

    2)
        echo ""
        echo -e "${YELLOW}重启服务...${NC}"
        docker compose restart

        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ 服务已重启${NC}"
            docker compose ps
        else
            echo -e "${RED}✗ 重启服务失败${NC}"
        fi
        ;;

    3)
        echo ""
        echo -e "${YELLOW}停止服务...${NC}"
        docker compose down

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 服务已停止${NC}"
        else
            echo -e "${RED}✗ 停止服务失败${NC}"
        fi
        ;;

    4)
        echo ""
        echo -e "${CYAN}=====================================${NC}"
        echo -e "${CYAN}   实时日志 (Ctrl+C 退出)${NC}"
        echo -e "${CYAN}=====================================${NC}"
        echo ""
        docker compose logs -f --tail=100
        ;;

    5)
        echo ""
        echo -e "${CYAN}=====================================${NC}"
        echo -e "${CYAN}   服务运行状态${NC}"
        echo -e "${CYAN}=====================================${NC}"
        echo ""
        docker compose ps
        echo ""
        echo -e "${CYAN}容器资源使用:${NC}"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
        echo ""
        echo -e "${CYAN}磁盘使用:${NC}"
        df -h | grep -E '(Filesystem|/$|/var/lib/docker)'
        ;;

    6)
        echo ""
        echo -e "${YELLOW}=====================================${NC}"
        echo -e "${YELLOW}   更新服务${NC}"
        echo -e "${YELLOW}=====================================${NC}"
        echo ""

        # 检查是否是 Git 仓库
        if [ -d ".git" ]; then
            echo -e "${YELLOW}拉取最新代码...${NC}"
            git pull

            if [ $? -ne 0 ]; then
                echo -e "${RED}✗ 拉取代码失败${NC}"
                exit 1
            fi
        else
            echo -e "${YELLOW}注意: 不是 Git 仓库，跳过拉取代码步骤${NC}"
        fi

        echo -e "${YELLOW}重新构建并启动服务...${NC}"
        docker compose down
        docker compose up -d --build

        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ 更新完成!${NC}"
            docker compose ps
        else
            echo -e "${RED}✗ 更新失败${NC}"
        fi
        ;;

    7)
        echo ""
        echo -e "${RED}=====================================${NC}"
        echo -e "${RED}   警告: 清理并重新部署${NC}"
        echo -e "${RED}=====================================${NC}"
        echo ""
        echo -e "${YELLOW}此操作将:${NC}"
        echo "  - 停止并删除所有容器"
        echo "  - 删除所有数据卷（包括数据库数据）"
        echo "  - 清理未使用的镜像"
        echo "  - 重新构建并启动服务"
        echo ""
        read -p "确定要继续? (yes/no): " confirm

        if [ "$confirm" = "yes" ]; then
            echo ""
            echo -e "${YELLOW}停止并删除容器...${NC}"
            docker compose down -v

            echo -e "${YELLOW}清理 Docker 资源...${NC}"
            docker system prune -f

            echo -e "${YELLOW}重新构建并启动...${NC}"
            docker compose up -d --build

            if [ $? -eq 0 ]; then
                echo ""
                echo -e "${GREEN}✓ 重新部署成功!${NC}"
                docker compose ps
            else
                echo -e "${RED}✗ 重新部署失败${NC}"
            fi
        else
            echo "取消操作"
        fi
        ;;

    8)
        echo ""
        echo -e "${YELLOW}=====================================${NC}"
        echo -e "${YELLOW}   备份数据库${NC}"
        echo -e "${YELLOW}=====================================${NC}"
        echo ""

        # 创建备份目录
        BACKUP_DIR="./backups"
        mkdir -p $BACKUP_DIR

        # 生成备份文件名
        BACKUP_FILE="glxt_backup_$(date +%Y%m%d_%H%M%S).bak"

        echo -e "${YELLOW}备份数据库到: $BACKUP_DIR/$BACKUP_FILE${NC}"

        # 执行备份
        docker compose exec -T sqlserver /opt/mssql-tools/bin/sqlcmd \
            -S localhost -U sa -P "Sym89@789Ab" \
            -Q "BACKUP DATABASE [GlxtDb] TO DISK = N'/var/opt/mssql/backup/$BACKUP_FILE' WITH FORMAT" \
            2>/dev/null

        if [ $? -eq 0 ]; then
            # 复制备份文件到主机
            docker cp glxt-sqlserver:/var/opt/mssql/backup/$BACKUP_FILE $BACKUP_DIR/

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ 数据库备份成功!${NC}"
                echo "备份位置: $BACKUP_DIR/$BACKUP_FILE"
                echo "文件大小: $(du -h $BACKUP_DIR/$BACKUP_FILE | cut -f1)"
            else
                echo -e "${RED}✗ 复制备份文件失败${NC}"
            fi
        else
            echo -e "${RED}✗ 数据库备份失败${NC}"
            echo "请检查数据库是否正常运行"
        fi
        ;;

    9)
        echo ""
        echo -e "${YELLOW}=====================================${NC}"
        echo -e "${YELLOW}   清理 Docker 资源${NC}"
        echo -e "${YELLOW}=====================================${NC}"
        echo ""

        echo "当前 Docker 磁盘使用:"
        docker system df
        echo ""

        read -p "是否清理未使用的资源? (y/N): " confirm

        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo -e "${YELLOW}清理中...${NC}"
            docker system prune -a -f

            echo ""
            echo -e "${GREEN}✓ 清理完成${NC}"
            echo ""
            echo "清理后磁盘使用:"
            docker system df
        else
            echo "取消操作"
        fi
        ;;

    *)
        echo -e "${RED}无效的选项${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}   操作完成${NC}"
echo -e "${GREEN}=====================================${NC}"
