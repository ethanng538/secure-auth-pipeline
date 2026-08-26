echo "Verifying brute-force rate limiting compliance across identity endpoints..."
RATE_LIMIT_BREACHED=0

# Dynamic port resolution queries
GATEWAY_PORT=$(docker port secure_frontend 80 | head -n 1 | grep -oE '[0-9]+$')
if [ -z "$GATEWAY_PORT" ]; then
    GATEWAY_PORT=$(docker port secure_frontend 443 | head -n 1 | grep -oE '[0-9]+$')
fi

# The target authentication routes
AUTH_ROUTES=("/api/login" "/api/register")

# Evaluates each distinct authentication route entry point
for ROUTE in "${AUTH_ROUTES[@]}"; do
  echo "Launching automated validation burst against $ROUTE..."

  # Temporary log file to collect concurrent HTTP status codes
    LOG_FILE=$(mktemp)

    # Simulates a high-speed script by firing 40 requests in parallel (simultaneous burst)
    for i in {1..40}; do
      (
        RESPONSE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
          -X POST http://localhost:$GATEWAY_PORT$ROUTE \
          -H "Content-Type: application/json" \
          -d '{"username":"dast_attacker","password":"password123"}')
        echo "$RESPONSE_STATUS" >> "$LOG_FILE"
      ) &
    done

    # Waits for all background parallel curls to complete before reading results
    wait

    # Checks if Nginx intercepted any of the concurrent traffic with a 429 status code
    if grep -q "429" "$LOG_FILE"; then
      echo "✅ Protection verified on $ROUTE (HTTP 429 received)."
      echo ""
    else
      echo "⚠️ DEBUG: Collected HTTP status codes: $(tr '\n' ' ' < "$LOG_FILE")"
      echo ""
      echo "🚨 APPSEC DETECTOR: Improper Restriction of Excessive Authentication Attempts (CWE-307)"
      echo ""
      echo "The authentication endpoint '$ROUTE' fails to restrict rapid traffic spikes."
      echo "An automated attacking script can fire unlimited high-speed requests down this path,"
      echo "leaving the application layer vulnerable to attacks such as denial-of-service (DoS)."
      echo ""
      echo "Remediation: Implement limit-rating zones at the Nginx edge proxy tier to intercept"
      echo "excessive request bursts before they reach internal application servers."
      echo ""
    RATE_LIMIT_BREACHED=1
  fi

  # Cleans up the temporary log file
  rm -f "$LOG_FILE"
done

# Pipeline failure enforcement gate
if [ $RATE_LIMIT_BREACHED -eq 1 ]; then
    exit 1
fi

echo "✅ Rate limiting validation complete. All authentication entry points are throttled."
echo ""
exit 0