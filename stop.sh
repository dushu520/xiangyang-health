#!/bin/bash

# 襄阳健康项目 - 停止服务脚本

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}正在停止服务...${NC}"

# 从 PID 文件读取并停止
if [ -f .backend.pid ]; then
    BACKEND_PID=$(cat .backend.pid)
    kill $BACKEND_PID 2>/dev/null && echo -e "${GREEN}后端服务已停止 (PID: $BACKEND_PID)${NC}" || true
    rm -f .backend.pid
fi

if [ -f .frontend.pid ]; then
    FRONTEND_PID=$(cat .frontend.pid)
    kill $FRONTEND_PID 2>/dev/null && echo -e "${GREEN}前端服务已停止 (PID: $FRONTEND_PID)${NC}" || true
    rm -f .frontend.pid
fi

# 强制杀死可能残留的进程
pkill -f "tsx server/index.ts" 2>/dev/null || true
pkill -f "vite --host" 2>/dev/null || true

echo -e "${GREEN}所有服务已停止${NC}"
