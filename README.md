# shinoyuki.cn

筱筱的个人导航仪表盘，基于 [Homepage](https://gethomepage.dev/) 构建。

## 功能

- **多服务器监控** — 通过 Glances 实时展示 3 台服务器（主服务器、副服务器、洛杉矶VPS）的 CPU / 内存 / 磁盘 / 网络负载
- **智能家居状态** — Home Assistant 联动米家，在网站上展示小窝的温度、湿度、灯光等信息
- **GitHub 动态** — 展示最近的开源活动和仓库信息
- **服务导航** — 一站式入口管理所有自托管服务
- **宝塔反代** — 通过宝塔面板配置反向代理和 HTTPS

## 架构

```
┌──────────────────────────────────────────────────────┐
│                shinoyuki.cn (Homepage)                │
├───────────┬───────────┬───────────┬──────────────────┤
│ 服务器监控  │ GitHub    │ 小窝信息   │ 书签 / 导航      │
│ (Glances)  │ (API)     │ (HA+米家)  │ (YAML)          │
└─────┬─────┴─────┬─────┴─────┬─────┴──────────────────┘
      │           │           │
      ▼           ▼           ▼
  3台服务器     GitHub      Home Assistant
  Glances       API       ┌──────────┐
  :39511                  │  米家设备  │
                          └──────────┘
```

## 项目结构

```
shinoyuki.cn/
├── docker-compose.yml              # 主服务器编排（Homepage + Glances + HA）
├── .env.example                    # 环境变量模板
├── config/
│   ├── homepage/                   # Homepage 配置
│   │   ├── settings.yaml           # 全局设置（主题、布局）
│   │   ├── services.yaml           # 服务和监控小组件
│   │   ├── bookmarks.yaml          # 书签链接
│   │   ├── widgets.yaml            # 顶部信息栏
│   │   ├── docker.yaml             # Docker 集成
│   │   ├── custom.css              # 自定义样式
│   │   └── custom.js               # 自定义脚本
│   └── glances/
│       └── glances.conf            # Glances 监控配置
└── remote/
    ├── docker-compose.glances.yml  # 远程服务器 Glances 编排
    └── deploy-glances.sh           # 远程服务器一键部署脚本
```

## 部署指南

### 前提条件

- 3 台 Ubuntu 服务器
- 所有服务器已安装 Docker + Docker Compose
- 域名 `shinoyuki.cn` 已解析到主服务器 IP

### 第一步：部署远程监控（副服务器 + 洛杉矶VPS）

分别 SSH 到副服务器和洛杉矶VPS，执行：

```bash
curl -fsSL https://raw.githubusercontent.com/xiaoxiao-cvs/shinoyuki.cn/main/remote/deploy-glances.sh | bash
```

或手动复制 `remote/deploy-glances.sh` 到服务器执行。

部署后确保防火墙放行 39511 端口：
```bash
sudo ufw allow 39511/tcp
```

### 第二步：配置主服务器

```bash
# 克隆仓库
git clone https://github.com/xiaoxiao-cvs/shinoyuki.cn.git
cd shinoyuki.cn

# 创建环境变量文件
cp .env.example .env
nano .env   # 填入实际的 HA Token 和服务器 IP
```

### 第三步：修改服务器 IP

编辑 `config/homepage/services.yaml`，将占位符替换为实际 IP：

- `副服务器IP` → 你的副服务器内网/公网 IP
- `洛杉矶VPS_IP` → 你的洛杉矶 VPS 公网 IP

### 第四步：启动服务

```bash
docker compose up -d
```

完成后登录宝塔面板，添加反向代理：

| 域名 | 目标地址 | 说明 |
|------|----------|------|
| `shinoyuki.cn` | `127.0.0.1:39510` | Homepage 主站 |
| `ha.shinoyuki.cn` | `127.0.0.1:39512` | Home Assistant |

在宝塔中开启 SSL 并勾选「强制 HTTPS」即可。

### 第五步：配置 Home Assistant

1. 访问 `http://主服务器IP:39512` 完成 HA 初始化
2. 安装 HACS（社区商店）：按照 [HACS 官方文档](https://hacs.xyz/) 操作
3. 在 HACS 中搜索安装 **Xiaomi Miot Auto** 插件
4. 用小米账号登录，自动发现米家设备
5. 在 HA 个人资料页面创建**长期访问令牌**，填入 `.env` 文件
6. 根据实际设备的 entity_id 修改 `services.yaml` 中的 HA 小组件配置

## 自定义

- 修改 `config/homepage/settings.yaml` 调整主题和布局
- 修改 `config/homepage/bookmarks.yaml` 增减书签链接
- 修改 `config/homepage/widgets.yaml` 调整天气位置坐标
- 参考 [Homepage 文档](https://gethomepage.dev/widgets/) 添加更多服务小组件
