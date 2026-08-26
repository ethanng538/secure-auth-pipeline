echo "Waiting for application to report healthy state..."
for i in {1..30}; do
  if curl -skL https://localhost/health | grep -q "healthy"; then
    echo "✅ Secured edge architecture is online and reporting a healthy state."
    exit 0
  fi
  sleep 2
done

echo "❌ Timeout: Application failed to initialise safely."
exit 1