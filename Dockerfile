# 自包含构建 — 从 GitHub 拉源码，安装依赖，启动 MCP server
FROM python:3.12-slim

WORKDIR /app

# 拉源码
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates && rm -rf /var/lib/apt/lists/*

RUN wget -q https://raw.githubusercontent.com/mumuer1024/ai-fishing-game/main/fishing.py -O /app/fishing.py && \
    wget -q https://raw.githubusercontent.com/mumuer1024/ai-fishing-game/main/examples/mcp-server/app/server.py -O /app/server.py && \
    wget -q https://raw.githubusercontent.com/mumuer1024/ai-fishing-game/main/examples/mcp-server/requirements.txt -O /app/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

# 复制存档同步脚本
COPY sync_save.py /app/sync_save.py

# 存档目录
RUN mkdir -p /app/data

ENV FISHING_HOST=0.0.0.0
ENV FISHING_PORT=3457
ENV FISHING_ENGINE=fishing
EXPOSE 3457

# sync_save.py 负责启动时从 Supabase 下载存档，退出时上传
# 内置自唤醒：每 9 分钟 self-ping 一次
CMD ["sh", "-c", "(while true; do sleep 540; wget -q -O /dev/null http://localhost:3457/mcp || true; done) & exec python sync_save.py"]
