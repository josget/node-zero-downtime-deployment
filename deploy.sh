#!/bin/bash

echo "Pulling"
git pull

echo "Building application"
sudo docker compose up -d --build
