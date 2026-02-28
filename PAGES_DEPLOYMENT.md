# EdgeOne Pages 部署设置方案

## 一、项目架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        EdgeOne Pages                            │
│                    (前端静态资源托管)                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   index.html │  │  /assets/    │  │ edgeone.json │          │
│  │   (HTML入口) │  │ (JS/CSS/图片)│  │ (缓存配置)   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ API 请求
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      云服务器 (后端)                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Express API │  │   SQLite     │  │  /uploads/   │          │
│  │   (Node.js)  │  │   (数据库)   │  │  (图片存储)  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## 二、构建设置

### 2.1 控制台配置

在 EdgeOne Pages 控制台创建项目时，填写以下构建设置：

| 配置项 | 值 | 说明 |
|--------|-----|------|
| **构建命令** | `pnpm run build` | 使用 pnpm 执行构建 |
| **输出目录** | `dist/public` | Vite 构建输出目录 |
| **Node 版本** | `20.18.0` | 建议选择 18+ 或 20+ |
| **包管理器** | `pnpm` | 与项目保持一致 |

### 2.2 构建流程说明

```bash
# EdgeOne Pages 会自动执行以下步骤：
1. pnpm install          # 安装依赖
2. pnpm run build        # 执行构建（vite build）
3. 部署 dist/public 目录  # 静态资源部署到边缘节点
```

**注意：** 当前项目构建命令同时构建前端和后端，但 EdgeOne Pages 只部署前端部分（`dist/public`），后端代码会被忽略。

## 三、环境变量配置

### 3.1 必需变量

在 EdgeOne Pages 控制台 → 项目设置 → 环境变量中添加：

```env
# 后端 API 地址（必须配置）
VITE_API_BASE_URL=https://your-backend-domain.com
```

**获取方式：**
- 如果你使用云服务器部署后端，填写服务器公网 IP 或域名
- 示例：`https://api.xiangyang.com` 或 `http://1.2.3.4:3000`

### 3.2 变量说明

| 变量名 | 必填 | 示例值 | 说明 |
|--------|------|--------|------|
| `VITE_API_BASE_URL` | ✅ | `https://api.xiangyang.com` | 后端 API 基础地址 |

### 3.3 多环境配置

EdgeOne Pages 支持多环境部署：

| 环境 | 分支 | `VITE_API_BASE_URL` 示例 |
|------|------|-------------------------|
| 生产环境 | `master` | `https://api.xiangyang.com` |
| 预览环境 | `develop` | `https://api-staging.xiangyang.com` |
| 功能预览 | `feature/*` | `https://api-dev.xiangyang.com` |

## 四、缓存策略配置

### 4.1 当前配置（edgeone.json）

已创建 `edgeone.json` 文件，配置如下：

```json
{
  "caches": [
    {
      "source": "/assets/*",
      "cacheTtl": 31536000    // 1年 - Vite 带 hash 的资源
    },
    {
      "source": "*.html",
      "cacheTtl": 600          // 10分钟 - HTML 入口
    }
  ],
  "headers": [
    {
      "source": "/assets/*.js",
      "headers": [{ "Cache-Control": "public, max-age=31536000, immutable" }]
    },
    {
      "source": "/assets/*.css",
      "headers": [{ "Cache-Control": "public, max-age=31536000, immutable" }]
    },
    {
      "source": "*.html",
      "headers": [{ "Cache-Control": "public, max-age=600" }]
    }
  ]
}
```

### 4.2 缓存行为说明

| 资源类型 | 边缘缓存 | 浏览器缓存 | 部署自动失效 |
|---------|---------|-----------|-------------|
| `/assets/*` (JS/CSS) | 1年 | 1年 (immutable) | ✅ 是 |
| `*.html` | 10分钟 | 10分钟 | ✅ 是 |

**重要：** 每次部署后，EdgeOne Pages 会自动使所有边缘缓存失效，确保用户获取最新内容。

## 五、域名配置

### 5.1 默认域名

部署后，EdgeOne Pages 会自动分配默认域名：

```
https://your-project-name.pages.edgeone.app
```

### 5.2 自定义域名（可选）

#### 方式一：CNAME 接入

1. 在 EdgeOne Pages 控制台 → 域名管理 → 添加域名
2. 填写你的域名，如：`www.xiangyang.com`
3. 在 DNS 服务商添加 CNAME 记录：
   ```
   类型: CNAME
   主机记录: www
   记录值: your-project-name.pages.edgeone.app
   ```
4. 等待 SSL 证书自动签发（通常 5-10 分钟）

#### 方式二：NS 接入（推荐国内用户）

1. 将域名 DNS 服务器改为 EdgeOne 提供的 NS 地址
2. 在控制台一键配置，自动处理所有解析

### 5.3 HTTPS 配置

EdgeOne Pages **自动提供 HTTPS**：
- ✅ 自动申请和续期 SSL 证书
- ✅ 支持 HTTP/2
- ✅ 自动 HTTP 重定向到 HTTPS

无需手动配置。

## 六、部署步骤

### 6.1 首次部署

1. **登录 EdgeOne Pages 控制台**
   - 访问：https://pages.edgeone.ai
   - 使用腾讯云账号登录

2. **创建项目**
   - 点击「创建项目」
   - 选择「从 Git 仓库导入」
   - 授权并选择 GitHub 仓库：`dushu520/xiangyang-health`
   - 选择分支：`feature/frontend-backend-separation`（或 `master`）

3. **配置构建设置**
   ```
   构建命令：pnpm run build
   输出目录：dist/public
   Node 版本：20.18.0
   ```

4. **配置环境变量**
   ```
   VITE_API_BASE_URL=https://your-backend-domain.com
   ```

5. **点击部署**
   - 等待构建完成（约 2-5 分钟）
   - 获取分配的域名

### 6.2 后续更新

代码推送到 Git 仓库后，EdgeOne Pages 会自动触发部署：

```bash
# 本地修改代码后
git add .
git commit -m "your commit message"
git push origin feature/frontend-backend-separation

# EdgeOne Pages 自动检测并重新部署
```

### 6.3 回滚

在 EdgeOne Pages 控制台 → 部署记录 → 选择历史版本 → 点击「回滚」

## 七、后端服务器配置

### 7.1 CORS 配置

后端服务器需要允许 EdgeOne Pages 的域名访问：

```env
# .env (后端服务器)
ALLOWED_ORIGINS="https://your-project.pages.edgeone.app,https://www.yourdomain.com"
```

### 7.2 Nginx 配置（如使用）

```nginx
server {
    listen 80;
    server_name api.xiangyang.com;

    # API 反向代理
    location /api {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # CORS 配置
        add_header 'Access-Control-Allow-Origin' 'https://your-project.pages.edgeone.app' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
    }

    # 上传文件访问
    location /uploads {
        alias /www/wwwroot/xiangyang/uploads;
        expires 365d;
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header Access-Control-Allow-Origin "*";
    }
}
```

## 八、验证测试

### 8.1 部署验证清单

- [ ] 首页正常加载
- [ ] 文章列表正常显示
- [ ] 图片正常加载（检查 `/uploads/` 路径）
- [ ] 后台登录功能正常
- [ ] 文章发布/编辑功能正常
- [ ] 图片上传功能正常

### 8.2 缓存验证

```bash
# 检查响应头
curl -I https://your-project.pages.edgeone.app/assets/index-xxx.js
# 应看到: Cache-Control: public, max-age=31536000, immutable

curl -I https://your-project.pages.edgeone.app/index.html
# 应看到: Cache-Control: public, max-age=600
```

### 8.3 网络面板检查

打开浏览器开发者工具 → Network：
- JS/CSS 请求状态码应为 `200` (from disk cache) 或 `304`
- 没有失败的请求（红色）
- API 请求正常返回数据

## 九、常见问题

### Q1: 构建失败，提示 "pnpm: command not found"

A: 在构建设置中选择正确的包管理器为 `pnpm`，或修改构建命令为：
```bash
npm install -g pnpm && pnpm install && pnpm run build
```

### Q2: API 请求返回 403/404

A: 检查：
1. `VITE_API_BASE_URL` 是否正确设置
2. 后端 CORS 配置是否包含前端域名
3. 后端服务是否正常运行

### Q3: 图片显示 404

A: 图片存储在后端服务器，检查：
1. 后端 `/uploads/` 目录可访问
2. Nginx 配置中 `alias` 路径正确
3. 数据库中图片路径使用完整 URL

### Q4: 如何查看构建日志？

A: EdgeOne Pages 控制台 → 部署记录 → 点击具体部署 → 查看日志

## 十、性能优化建议

### 10.1 已优化项

- ✅ 静态资源长期缓存（immutable）
- ✅ 系统字体（无外部字体依赖）
- ✅ 移除 Google 服务（国内可访问）
- ✅ EdgeOne 全球 CDN 加速

### 10.2 可选优化

1. **开启 Brotli 压缩**
   - EdgeOne 默认开启，无需配置

2. **图片优化**
   - 使用 WebP 格式
   - 开启 EdgeOne 图片处理服务

3. **懒加载**
   - 已在前端代码中实现图片懒加载

---

## 相关文档

- [EdgeOne Pages 官方文档](https://pages.edgeone.ai/zh/document)
- [edgeone.json 配置详解](https://pages.edgeone.ai/zh/document/edgeone-json)
- 本项目后端部署文档：[DEPLOYMENT.md](./DEPLOYMENT.md)
