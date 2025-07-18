#!/usr/bin/env bash
# Simple helper to generate telemetry from rolldice app

set -euo pipefail

kubectl port-forward svc/rolldice 8080:80 &
PF_PID=$!

# give port-forward time to establish
sleep 2

# hit the endpoint a few times to produce traces/logs
for i in {1..5}; do
  curl -s http://localhost:8080/roll || true
  sleep 1
done

kill $PF_PID
