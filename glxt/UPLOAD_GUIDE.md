# 快速上传到服务器

## 使用方法

在 PowerShell 中运行：

```powershell
.\glxt\upload-to-server.ps1
```

## 步骤说明

1. **输入服务器信息**
   - 服务器 IP 地址（例如：192.168.1.100）
   - 服务器用户名（默认：root）
   - 部署路径（默认：/app/glxt）

2. **确认上传**
   - 输入 Y 确认上传
   - 输入 N 取消操作

3. **自动上传**
   - 脚本会自动压缩项目
   - 上传到服务器
   - 解压并准备部署环境

4. **选择是否立即部署**
   - 输入 Y 立即在服务器上启动部署
   - 输入 N 稍后手动部署

## 示例

```powershell
# 直接指定参数运行
.\glxt\upload-to-server.ps1 -ServerIP "192.168.1.100" -ServerUser "root" -ServerPath "/app/glxt"
```

## 注意事项

1. **SSH 配置**
   - 确保可以通过 SSH 连接到服务器
   - 推荐配置 SSH 密钥认证以免密登录

2. **服务器要求**
   - 已安装 Docker 和 Docker Compose
   - 有足够的磁盘空间
   - 防火墙已开放相应端口

3. **网络连接**
   - 确保网络连接稳定
   - 上传可能需要几分钟时间

## 手动部署

如果选择不立即部署，稍后可以手动执行：

```bash
# SSH 连接到服务器
ssh root@YOUR_SERVER_IP

# 进入项目目录
cd /app/glxt

# 运行部署脚本
./deploy-server.sh

# 选择选项 1：构建并启动服务
```

## 故障排查

### 问题 1：SSH 连接失败
- 检查服务器 IP 是否正确
- 检查 SSH 服务是否运行
- 检查防火墙是否允许 SSH 连接

### 问题 2：上传失败
- 检查网络连接
- 确认有写入权限
- 检查磁盘空间是否足够

### 问题 3：权限错误
```bash
# 在服务器上修复权限
chmod +x /app/glxt/deploy-server.sh
```

## 相关文件

- `upload-to-server.ps1` - 上传脚本
- `deploy-server.sh` - 服务器部署脚本
- `CLOUD_DEPLOY_README.md` - 完整部署指南
