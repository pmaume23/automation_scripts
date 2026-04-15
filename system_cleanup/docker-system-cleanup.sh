#!/usr/bin/env bash
set -euo pipefail

echo "[Cleanup] Stopping all running containers (if any)..."
if [ -n "$(docker ps -q)" ]; then
  docker stop $(docker ps -q)
else
  echo "No running containers."
fi

echo "[Cleanup] Removing all containers (running/exited)..."
if [ -n "$(docker ps -aq)" ]; then
  docker rm -f $(docker ps -aq)
else
  echo "No containers to remove."
fi

echo "[Cleanup] Removing all images..."
if [ -n "$(docker images -q)" ]; then
  docker rmi -f $(docker images -q)
else
  echo "No images to remove."
fi

echo "[Cleanup] Pruning build cache..."
docker builder prune -af

echo "[Cleanup] Done."