# 自包含构建 — 从 GitHub 拉源码，安装依赖，启动 MCP server
FROM python:3.12-slim

WORKDIR /app

# 拉源码
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates && rm -rf /var/lib/apt/lists/*

RUN wget -q https://raw.githubusercontent.com/mumuer1024/ai-fishing-game/main/fishing.py -O /app/fishing.py && \
    wget -q https://raw.githubusercontent.com/mumuer1024/ai-fishing-game/main/examples/mcp-server/app/server.py -O /app/server.py && \
    wget -q https://raw.githubusercontent.com/mumuer1024/ai-fishing-game/main/examples/mcp-server/requirements.txt -O /app/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

ENV FISHING_HOST=0.0.0.0
ENV FISHING_PORT=3457
ENV FISHING_ENGINE=fishing
EXPOSE 3457

CMD ["python", "server.py"]
