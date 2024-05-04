#!/bin/bash

# Exit if no service name is provided
SERVICE_NAME=${1?"Usage: $0 <SERVICE_NAME>"}

echo "[INIT] Rebuilding docker service $SERVICE_NAME"
docker compose build $SERVICE_NAME

echo "[INIT] Updating docker service $SERVICE_NAME"

# Fetch the oldest running container's ID and name for the service
OLD_CONTAINER_ID=$(docker ps --format "{{.ID}}  {{.Names}}" | grep $SERVICE_NAME | head -n 1 | awk '{print $1}')
OLD_CONTAINER_NAME=$(docker ps --format "{{.ID}}  {{.Names}}" | grep $SERVICE_NAME | head -n 1 | awk '{print $2}')

echo "[INIT] Scaling $SERVICE_NAME up"
docker compose up -d --no-deps --scale $SERVICE_NAME=2 --no-recreate

# Wait until a newer container than the last recorded is up
NEW_CONTAINER_ID=""
while [[ -z $NEW_CONTAINER_ID || $NEW_CONTAINER_ID == $LATEST_CONTAINER_ID ]]; do
  echo -ne "[WAIT] Creating new container for $SERVICE_NAME..."
  sleep 1  # Short delay to prevent overwhelming the CPU
  # Fetch the latest started container's ID and name for the service
  NEW_CONTAINER_ID=$(docker ps --format "{{.ID}}  {{.Names}}" | grep $SERVICE_NAME | tail -n 1 | awk '{print $1}')
  NEW_CONTAINER_NAME=$(docker ps --format "{{.ID}}  {{.Names}}" | grep $SERVICE_NAME | tail -n 1 | awk '{print $2}')
done

# Wait until the new container is healthy
while [[ -z $(docker ps -a -f "id=$NEW_CONTAINER_ID" -f "health=healthy" -q) ]]; do
  echo "[WAIT] New instance $NEW_CONTAINER_NAME is not healthy yet ..."
  sleep 1
done
echo ""
echo "[DONE] $NEW_CONTAINER_NAME is ready!"

echo "[DONE] Restarting caddy.."
docker compose restart caddy

echo -n "[INIT] Killing $OLD_CONTAINER_NAME: "
docker stop $OLD_CONTAINER_ID
while [[ -z $(docker ps -a -f "id=$OLD_CONTAINER_ID" -f "status=exited" -q) ]]; do
  echo -ne "[WAIT] $OLD_CONTAINER_NAME is getting killed ..."
  sleep 1
done
echo ""
echo "[DONE] $OLD_CONTAINER_NAME was stopped."

echo -n "[DONE] Removing $OLD_CONTAINER_NAME: "
docker rm -f $OLD_CONTAINER_ID
echo "[DONE] Scaling down"
docker compose up -d --no-deps --scale $SERVICE_NAME=1 --no-recreate

echo "[DONE] Deployment completed successfully 🎉🎉🎉"
