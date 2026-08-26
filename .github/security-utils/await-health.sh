echo "Waiting for application to report healthy state..."
for i in {1..30}; do
  if curl -skL https://localhost/health | grep -q "healthy"; then
    echo "✅ Secured edge architecture is online and reporting a healthy state."
    exit 0
  fi
  sleep 2
done

echo "❌ Timeout: Application failed to initialise safely."
echo "=== 📊 DEBUGGING INFO: Container Status ==="
docker compose ps
echo ""

echo "=== 📋 DEBUGGING INFO: Recent Container Logs ==="
docker compose logs --tail=50
echo ""

echo "=== NGINX DESCRIPTOR LOGS ==="
docker compose logs frontend-ui
echo ""

echo "=== BACKEND RUNTIME LOGS ==="
docker compose logs backend-api
echo ""
exit 1