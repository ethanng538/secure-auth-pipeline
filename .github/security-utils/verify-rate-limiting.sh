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
  ROUTE_THROTTLED=0

  # Simulates a quick high-speed script (20 requests)
  for i in {1..20}; do
    RESPONSE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
      -X POST http://localhost:$GATEWAY_PORT$ROUTE \
      -H "Content-Type: application/json" \
      -d '{"username":"dast_attacker","password":"password123"}')

    # If the proxy intercepts the traffic with a 429 status code, it passes
    if [ "$RESPONSE_STATUS" = "429" ]; then
      ROUTE_THROTTLED=1
      break
    fi
  done

  # If the endpoint let all 20 requests fly without a 429, it's a vulnerability
  if [ $ROUTE_THROTTLED -eq 0 ]; then
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
  else
    echo "✅ Protection verified on $ROUTE (HTTP 429 received)."
  fi
done

# Pipeline failure enforcement gate
if [ $RATE_LIMIT_BREACHED -eq 1 ]; then
    exit 1
fi

echo "✅ Rate limiting validation complete. All authentication entry points are throttled."
exit 0