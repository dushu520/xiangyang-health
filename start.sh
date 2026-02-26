#!/bin/bash

# 襄阳健康项目 - 开发环境启动脚本
# 使用 nodemon 实现后端自动重启

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  襄阳健康项目 - 开发环境启动${NC}"
echo -e "${BLUE}========================================${NC}"

# 检查是否安装了 nodemon
if ! command -v nodemon &> /dev/null; then
    echo -e "${YELLOW}nodemon 未安装，正在安装...${NC}"
    pnpm add -D nodemon
fi

# 清理之前的后台进程
echo -e "${YELLOW}清理之前的进程...${NC}"
pkill -f "tsx server/index.ts" 2>/dev/null || true
pkill -f "vite --host" 2>/dev/null || true

# 创建 logs 目录
mkdir -p logs

# 启动后端服务 (使用 nodemon 自动重启)
echo -e "${GREEN}启动后端服务 (端口 3000)...${NC}"
pnpm exec nodemon --exec "tsx" --watch "server" --ext "ts" --ignore "logs/*" server/index.ts > logs/backend.log 2>&1 &
BACKEND_PID=$!
echo -e "  PID: ${BACKEND_PID}"

# 等待后端启动
sleep 2

# 启动前端服务
echo -e "${GREEN}启动前端服务 (端口 5173)...${NC}"
pnpm dev > logs/frontend.log 2>&1 &
FRONTEND_PID=$!
echo -e "  PID: ${FRONTEND_PID}"

# 保存 PID 到文件
echo $BACKEND_PID > .backend.pid
echo $FRONTEND_PID > .frontend.pid

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}启动完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "  前端: ${GREEN}http://localhost:5173${NC}"
echo -e "  后端: ${GREEN}http://localhost:3000${NC}"
echo -e ""
echo -e "  日志文件:"
echo -e "    后端: ${YELLOW}tail -f logs/backend.log${NC}"
echo -e "    前端: ${YELLOW}tail -f logs/frontend.log${NC}"
echo -e ""
echo -e "  停止服务: ${YELLOW}./stop.sh${NC}"
echo -e "${BLUE}========================================${NC}"

# 实时显示日志
echo -e "${YELLOW}按 Ctrl+C 停止所有服务${NC}"
echo -e ""

# 使用 trap 捕获退出信号
trap "echo -e '${RED}正在停止服务...${NC}'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; rm -f .backend.pid .frontend.pid; exit 0" INT TERM

# 等待进程
wait $BACKEND_PID $FRONTEND_PID
