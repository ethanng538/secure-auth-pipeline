echo "Waiting for application to report healthy state..."
for i in {1..30}; do
  if curl -skL http://localhost:3000/health | grep -q "healthy"; then
    echo "✅ Application is online and reporting a healthy state."
    exit 0
  fi
  sleep 2
done

echo "❌ Timeout: Application failed to initialise safely."
exit 1