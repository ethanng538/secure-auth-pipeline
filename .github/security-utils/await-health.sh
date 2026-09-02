echo "Waiting for application to report healthy state..."
for i in {1..30}; do
  if curl -skL https://localhost:3443/health | grep -q "healthy"; then
    echo "✅ Frontend UI proxy is online and reporting a healthy state."
    exit 0
  fi
  sleep 2
done

echo "❌ Timeout: Application failed to initialise safely."
echo "=== Container status ==="
docker compose ps
echo ""

echo "=== Recent container logs ==="
docker compose logs --tail=50
echo ""

echo "=== Nginx descriptor logs ==="
docker compose logs frontend-ui
echo ""

echo "=== Backend runtime logs ==="
docker compose logs backend-api
exit 1