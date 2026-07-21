# 自包含构建 — 从 GitHub 拉源码，安装依赖，启动 MCP server
FROM python:3.12-slim

WORKDIR /app

# 拉源码
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates && rm -rf /var/lib/apt/lists/*

RUN wget -q https://raw.githubusercontent.com/mumuer1024/ai-fishing-game/main/fishing.py -O /app/fishing.py && \
    wget -q https://raw.githubusercontent.com/mumuer1024/ai-fishing-game/main/examples/mcp-server/app/server.py -O /app/server.py && \
    wget -q https://raw.githubusercontent.com/mumuer1024/ai-fishing-game/main/examples/mcp-server/requirements.txt -O /app/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

# 存档目录（Render Disk 挂载点，跨部署持久化）
RUN mkdir -p /app/data

ENV FISHING_HOST=0.0.0.0
ENV FISHING_PORT=3457
ENV FISHING_ENGINE=fishing
EXPOSE 3457

# 内置自唤醒：每 9 分钟 self-ping 一次，防止 Render 免费层休眠
# 后台 while 循环用 wget 请求本地 /mcp；sleep 540 = 9 分钟，留 6 分钟余量
CMD ["sh", "-c", "(while true; do sleep 540; wget -q -O /dev/null http://localhost:3457/mcp || true; done) & exec python server.py"]
