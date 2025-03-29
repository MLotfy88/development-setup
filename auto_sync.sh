#!/bin/bash
while true; do
  cd /root/workspace/project
  git pull origin main
  sleep 60
done
