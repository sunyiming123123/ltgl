# GLXT - Windows 一键部署指南

## 🚀 最简单的部署方式（适用于 Windows）

### ✅ 前提条件

1. **确保 Windows 安装了 SSH 客户端**（Windows 10/11 自带）
   ```powershell
   # 测试 SSH 是否可用
   ssh -V
   ```

2. **阿里云安全组开放端口**：
   - **22** - SSH 连接
   - **5000** - HTTP 访问
   - **5001** - HTTPS 访问

---

## 📋 一键部署步骤

### 第一步：打开 PowerShell

在项目根目录右键，选择 **"在终端中打开"** 或手动进入：

```powershell
cd D:\test\glxt\glxt
```

### 第二步：执行部署脚本

```powershell
.\deploy-windows.ps1
```

### 第三步：输入服务器密码

脚本会提示输入服务器密码，输入后按回车即可。

**脚本会自动完成：**
- ✅ 连接到阿里云服务器（139.224.245.244）
- ✅ 安装 Docker 和 Docker Compose
- ✅ 克隆/更新项目代码
- ✅ 构建并启动所有服务
- ✅ 显示部署状态

---

## 🌐 访问应用

部署完成后，在浏览器访问：

```
http://139.224.245.244:5000
```

---

## 🔧 常用操作

### 查看日志

```powershell
# 连接到服务器
ssh root@139.224.245.244

# 进入项目目录
cd GLXT/glxt

# 查看实时日志
docker-compose logs -f
```

### 重启服务

```powershell
ssh root@139.224.245.244 "cd GLXT/glxt && docker-compose restart"
```

### 停止服务

```powershell
ssh root@139.224.245.244 "cd GLXT/glxt && docker-compose stop"
```

### 更新部署

```powershell
# 重新运行部署脚本即可
.\deploy-windows.ps1
```

---

## ❌ 错误解决

### 1. SSH 连接被拒绝

**错误信息：**
```
Could not resolve hostname root
```

**解决方法：**
- 确保使用完整的 IP 地址：`ssh root@139.224.245.244`
- 检查阿里云安全组是否开放 22 端口

### 2. 无法连接到服务器

**解决方法：**
1. 登录 [阿里云控制台](https://ecs.console.aliyun.com/)
2. 进入 **安全组 → 配置规则**
3. 添加入方向规则：
   - 端口范围：22/22
   - 授权对象：0.0.0.0/0
   - 协议类型：TCP

### 3. Docker 镜像下载慢

**解决方法：**
连接服务器后，配置国内镜像源：

```bash
ssh root@139.224.245.244

# 配置 Docker 镜像加速
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ]
}
EOF

# 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## 📦 服务器上的目录结构

```
/root/
└── GLXT/
    └── glxt/
        ├── Dockerfile
        ├── docker-compose.yml
        ├── deploy.sh
        └── ... (其他项目文件)
```

---

## 🔑 配置 SSH 密钥（可选）

如果不想每次输入密码，可以配置 SSH 密钥：

```powershell
# 1. 生成密钥（如果没有）
ssh-keygen -t rsa -b 4096

# 2. 复制公钥到服务器
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh root@139.224.245.244 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# 3. 之后就可以免密码登录了
ssh root@139.224.245.244
```

---

## 💡 提示

- 首次部署需要 5-10 分钟（下载 Docker 镜像）
- SQL Server 需要至少 2GB 内存
- 数据保存在 Docker volume 中，重启不会丢失
- 建议定期备份数据库

---

## 📞 需要帮助？

如果遇到问题，可以：
1. 查看详细日志：`ssh root@139.224.245.244 "cd GLXT/glxt && docker-compose logs"`
2. 检查服务状态：`ssh root@139.224.245.244 "cd GLXT/glxt && docker-compose ps"`
3. 重新部署：`.\deploy-windows.ps1`
