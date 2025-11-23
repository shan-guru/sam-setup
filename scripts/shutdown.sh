#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CONFIG_FILE="${1:-$PROJECT_ROOT/config/config.yaml}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file '$CONFIG_FILE' not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}Shutting down SAM Local Environment...${NC}"

# Function to read YAML config (simple parser for nested keys)
read_yaml() {
    local section="$1"
    local key="$2"
    awk "/^${section}:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^  ${key}:/{print}" "$CONFIG_FILE" | \
        sed 's/^  [^:]*: *//' | \
        sed 's/^"\(.*\)"$/\1/' | \
        sed 's/#.*$//' | \
        xargs
}

# Extract container name and SAM port
CONTAINER_NAME=$(read_yaml "dynamodb_local" "container_name")
SAM_PORT=$(read_yaml "sam" "port")

# Stop and remove DynamoDB Local container using docker-compose
cd "$PROJECT_ROOT/config"
if [ -f "docker-compose.yml" ]; then
    # Determine docker-compose command
    if command -v docker-compose > /dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        DOCKER_COMPOSE_CMD="docker compose"
    fi
    
    if $DOCKER_COMPOSE_CMD ps dynamodb-local 2>/dev/null | grep -q "Up"; then
        echo -e "${YELLOW}Stopping DynamoDB Local container...${NC}"
        $DOCKER_COMPOSE_CMD stop dynamodb-local > /dev/null 2>&1 || true
        echo -e "${GREEN}✓ DynamoDB Local container stopped${NC}"
    fi
    
    if $DOCKER_COMPOSE_CMD ps -a dynamodb-local 2>/dev/null | grep -q "dynamodb-local"; then
        echo -e "${YELLOW}Removing DynamoDB Local container...${NC}"
        $DOCKER_COMPOSE_CMD rm -f dynamodb-local > /dev/null 2>&1 || true
        echo -e "${GREEN}✓ DynamoDB Local container removed${NC}"
    else
        echo -e "${YELLOW}DynamoDB Local container not found${NC}"
    fi
else
    # Fallback to manual docker commands if docker-compose.yml doesn't exist
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}Stopping DynamoDB Local container...${NC}"
        docker stop "$CONTAINER_NAME" > /dev/null
        echo -e "${GREEN}✓ DynamoDB Local container stopped${NC}"
    fi
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}Removing DynamoDB Local container...${NC}"
        docker rm "$CONTAINER_NAME" > /dev/null 2>&1 || true
        echo -e "${GREEN}✓ DynamoDB Local container removed${NC}"
    else
        echo -e "${YELLOW}DynamoDB Local container not found${NC}"
    fi
fi

# Kill SAM Local API if running (find process on SAM port)
if lsof -ti:$SAM_PORT > /dev/null 2>&1; then
    echo -e "${YELLOW}Stopping SAM Local API on port $SAM_PORT...${NC}"
    kill $(lsof -ti:$SAM_PORT) 2>/dev/null || true
    echo -e "${GREEN}✓ SAM Local API stopped${NC}"
else
    echo -e "${YELLOW}SAM Local API is not running${NC}"
fi

echo -e "${GREEN}✓ Shutdown complete${NC}"

