echo "Auditing container configurations for direct host port exposure..."
VIOLATION_DETECTED=0
CONTAINERS=$(docker ps -q)

for CONTAINER_ID in $CONTAINERS; do
  CONTAINER_NAME=$(docker inspect --format='{{.Name}}' $CONTAINER_ID | sed 's/\///')
  PORT_BINDINGS=$(docker inspect --format='{{json .NetworkSettings.Ports}}' $CONTAINER_ID)

  if [ "$CONTAINER_NAME" = "secure_frontend" ]; then
    continue
  fi

  if [ "$PORT_BINDINGS" != "null" ] && [ "$PORT_BINDINGS" != "{}" ] && [ ! -z "$PORT_BINDINGS" ]; then
    echo "🚨 SECURITY VIOLATION: Container '$CONTAINER_NAME' is exposing internal data paths directly to the host!"
    echo "   Leaked network configurations: $PORT_BINDINGS"
    VIOLATION_DETECTED=1
  fi
done

if [ $VIOLATION_DETECTED -eq 1 ]; then
  echo "Pipeline halted. Rectify the docker-compose.yml file by removing unapproved 'ports' configurations."
  exit 1
fi
echo "Perimeter validation complete. All microservices are safely isolated behind the edge proxy."