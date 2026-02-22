#!/bin/bash
# ============================================
# 远程服务器 Glances 一键部署脚本
# 用法: bash deploy-glances.sh
# 在副服务器和洛杉矶VPS上分别执行
# ============================================

set -e

echo "=========================================="
echo "  Glances 监控端一键部署"
echo "=========================================="

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "[信息] 未检测到 Docker，正在安装..."
    curl -fsSL https://get.docker.com | sh
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "[完成] Docker 安装成功"
fi

# 检查 Docker Compose
if ! docker compose version &> /dev/null; then
    echo "[信息] 未检测到 Docker Compose V2，正在安装..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    echo "[完成] Docker Compose 安装成功"
fi

# 创建工作目录
WORK_DIR="$HOME/glances"
mkdir -p "$WORK_DIR"

# 写入 docker-compose.yml
cat > "$WORK_DIR/docker-compose.yml" << 'EOF'
services:
  glances:
    image: nicolargo/glances:latest-full
    container_name: glances
    restart: unless-stopped
    ports:
      - 39511:61208
    environment:
      - GLANCES_OPT=-w
      - TZ=Asia/Shanghai
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    pid: host
    network_mode: host
EOF

# 启动
cd "$WORK_DIR"
docker compose pull
docker compose up -d

echo ""
echo "=========================================="
echo "  Glances 部署完成！"
echo "  访问: http://$(hostname -I | awk '{print $1}'):39511"
echo "=========================================="
echo ""
echo "[提醒] 请确保防火墙放行 39511 端口"
echo "  sudo ufw allow 39511/tcp"
