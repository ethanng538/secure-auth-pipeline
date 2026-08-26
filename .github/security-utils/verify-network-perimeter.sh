echo "Auditing environment network perimeter isolation boundaries..."
PERIMETER_BREACHED=0

# Fetch a collection of all running container IDs
CONTAINERS=$(docker ps -q)

for CONTAINER_ID in $CONTAINERS; do
  # Extract friendly container name
  CONTAINER_NAME=$(docker inspect --format='{{.Name}}' $CONTAINER_ID | sed 's/\///')

  # Skip checking our allowed public front door entry point
  if [ "$CONTAINER_NAME" = "secure_frontend" ]; then
    continue
  fi

  # Looks for explicitly declared "ports" configuration arrays
  PORT_BINDINGS=$(docker inspect --format='{{json .NetworkSettings.Ports}}' $CONTAINER_ID)
    if [ "$PORT_BINDINGS" != "null" ] && [ "$PORT_BINDINGS" != "{}" ] && [ ! -z "$PORT_BINDINGS" ]; then
      # Extracts the host ports cleanly from the JSON structure
      HOST_PORTS=$(echo "$PORT_BINDINGS" | grep -oE '"HostPort":"[0-9]+"' | grep -oE '[0-9]+' | sort -u | tr '\n' ',' | sed 's/,$//')

      if [ ! -z "$HOST_PORTS" ]; then
        echo "🚨 APPSEC DETECTOR: Exposure of Sensitive System Information via Configuration (CWE-200 / CWE-497)"
        echo ""
        echo "The infrastructure configuration profile explicitly publishes internal service ports straight to the host interface."
        echo "External reconnaissance tools can locate these backend components, completely bypassing edge reverse proxy access controls."
        echo ""
        echo "Remediation: Remove the 'ports' block definition from the '$CONTAINER_NAME' service in the root docker-compose.yml file."
        echo ""
        PERIMETER_BREACHED=1
      fi
    fi

  # Extract the container's internal exposed ports
  EXPOSED_PORTS=$(docker inspect --format='{{json .Config.ExposedPorts}}' $CONTAINER_ID | grep -oE '[0-9]+' | sort -u)

  for PORT in $EXPOSED_PORTS; do
    if (echo > /dev/tcp/127.0.0.1/$PORT) >/dev/null 2>&1; then
      echo "🚨 APPSEC DETECTOR: Exposure of Sensitive System Information via Live Port (CWE-200 / CWE-497)"
      echo ""
      echo "A live connection was successfully accepted on unapproved Port $PORT mapped to '$CONTAINER_NAME'."
      echo "This open network backdoor bypasses perimeter security guardrails and exposes the application's underlying ecosystem directly to the host network interface."
      echo ""
      echo "Remediation: Confine service communications exclusively to isolated virtual bridge networks by stripping public port maps."
      echo ""
      PERIMETER_BREACHED=1
    fi
  done
done

# Pipeline failure enforcement gate
if [ $PERIMETER_BREACHED -eq 1 ]; then
  exit 1
fi

echo "✅ Perimeter validation complete. External boundaries are secure."
exit 0