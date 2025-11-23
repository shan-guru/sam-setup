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

# Parse arguments
RESTART_MODE=false
SETUP_TABLE=false
CONFIG_FILE="${CONFIG_DIR:-$PROJECT_ROOT/config/config.yaml}"

# Show usage if help requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [OPTIONS] [CONFIG_FILE]"
    echo ""
    echo "Options:"
    echo "  -r, --restart    Force restart: stop and clean up existing services before starting"
    echo "  -c, --config     Specify config file (default: config.yaml)"
    echo "  -s, --setup      Automatically set up DynamoDB table after starting services"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Start with default config.yaml"
    echo "  $0 --restart          # Force restart all services"
    echo "  $0 -r -s              # Restart and set up DynamoDB table"
    echo "  $0 -r custom.yaml     # Restart with custom config file"
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--restart)
            RESTART_MODE=true
            shift
            ;;
        -s|--setup)
            SETUP_TABLE=true
            shift
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            # Help already handled above, but include here for completeness
            exit 0
            ;;
        *)
            # Only treat as config file if it doesn't start with - and is a file
            if [[ "$1" != -* ]] && [ -f "$1" ]; then
                CONFIG_FILE="$1"
            elif [[ "$1" == -* ]]; then
                echo -e "${RED}Error: Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 1
            fi
            shift
            ;;
    esac
done

CONFIG_FILE="${CONFIG_FILE:-config.yaml}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file '$CONFIG_FILE' not found!${NC}"
    exit 1
fi

# Function to read YAML config (needed for restart)
read_yaml() {
    local section="$1"
    local key="$2"
    awk "/^${section}:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^  ${key}:/{print}" "$CONFIG_FILE" | \
        sed 's/^  [^:]*: *//' | \
        sed 's/^"\(.*\)"$/\1/' | \
        sed 's/#.*$//' | \
        xargs
}

# Restart mode: stop and clean up existing services
if [ "$RESTART_MODE" = true ]; then
    echo -e "${YELLOW}Restart mode: Cleaning up existing services...${NC}"
    
    # Extract container name and SAM port for cleanup
    CONTAINER_NAME=$(read_yaml "dynamodb_local" "container_name")
    SAM_PORT=$(read_yaml "sam" "port")
    
    # Stop and remove DynamoDB container using docker-compose
    if [ -f "$PROJECT_ROOT/config/docker-compose.yml" ]; then
        # Determine docker-compose command
        if command -v docker-compose > /dev/null 2>&1; then
            DOCKER_COMPOSE_CMD="docker-compose"
        else
            DOCKER_COMPOSE_CMD="docker compose"
        fi
        
        echo -e "${YELLOW}Stopping DynamoDB Local container...${NC}"
        $DOCKER_COMPOSE_CMD down dynamodb-local > /dev/null 2>&1 || true
    else
        # Fallback to manual docker commands if docker-compose.yml doesn't exist
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo -e "${YELLOW}Stopping DynamoDB Local container...${NC}"
            docker stop "$CONTAINER_NAME" > /dev/null 2>&1 || true
        fi
        
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo -e "${YELLOW}Removing DynamoDB Local container...${NC}"
            docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true
        fi
    fi
    
    # Kill SAM Local API if running
    if lsof -ti:$SAM_PORT > /dev/null 2>&1; then
        echo -e "${YELLOW}Stopping SAM Local API on port $SAM_PORT...${NC}"
        kill $(lsof -ti:$SAM_PORT) 2>/dev/null || true
        sleep 1
    fi
    
    echo -e "${GREEN}✓ Cleanup complete, starting fresh...${NC}"
    echo ""
fi

echo -e "${GREEN}Starting SAM Local Environment...${NC}"


# Extract config values
AWS_ACCESS_KEY_ID=$(read_yaml "aws" "access_key_id")
AWS_SECRET_ACCESS_KEY=$(read_yaml "aws" "secret_access_key")
AWS_REGION=$(read_yaml "aws" "region")
DYNAMODB_PORT=$(read_yaml "dynamodb_local" "port")
DYNAMODB_IMAGE=$(read_yaml "dynamodb_local" "image")
CONTAINER_NAME=$(read_yaml "dynamodb_local" "container_name")
DYNAMODB_HOST=$(read_yaml "dynamodb_local" "host")
SAM_PORT=$(read_yaml "sam" "port")
WARM_CONTAINERS=$(read_yaml "sam" "warm_containers")
DOCKER_NETWORK=$(read_yaml "sam" "docker_network")

# Validate required values
if [ -z "$DYNAMODB_PORT" ] || [ -z "$DYNAMODB_IMAGE" ] || [ -z "$CONTAINER_NAME" ]; then
    echo -e "${RED}Error: Failed to parse required DynamoDB Local configuration from $CONFIG_FILE${NC}"
    exit 1
fi

if [ -z "$SAM_PORT" ] || [ -z "$WARM_CONTAINERS" ]; then
    echo -e "${RED}Error: Failed to parse required SAM configuration from $CONFIG_FILE${NC}"
    exit 1
fi

# AWS Credential Management (Option C: AWS CLI Configuration)
# Priority: Environment variables > AWS CLI credentials > config.yaml
# For local SAM development, we use config.yaml values (can be dummy for DynamoDB Local)
# For real AWS operations, AWS SDK will automatically use AWS CLI credentials

# Check if AWS CLI credentials are available
AWS_CLI_PROFILE="${AWS_PROFILE:-default}"
if command -v aws > /dev/null 2>&1; then
    # Try to get credentials from AWS CLI
    AWS_CLI_ACCESS_KEY=$(aws configure get aws_access_key_id --profile "$AWS_CLI_PROFILE" 2>/dev/null || echo "")
    AWS_CLI_SECRET_KEY=$(aws configure get aws_secret_access_key --profile "$AWS_CLI_PROFILE" 2>/dev/null || echo "")
    AWS_CLI_REGION=$(aws configure get region --profile "$AWS_CLI_PROFILE" 2>/dev/null || echo "")
    
    # Use AWS CLI credentials if available, otherwise use config.yaml
    if [ -n "$AWS_CLI_ACCESS_KEY" ] && [ -n "$AWS_CLI_SECRET_KEY" ]; then
        echo -e "${GREEN}Using AWS CLI credentials (profile: $AWS_CLI_PROFILE)${NC}"
        AWS_ACCESS_KEY_ID="$AWS_CLI_ACCESS_KEY"
        AWS_SECRET_ACCESS_KEY="$AWS_CLI_SECRET_KEY"
        if [ -n "$AWS_CLI_REGION" ]; then
            AWS_REGION="$AWS_CLI_REGION"
        fi
    else
        echo -e "${YELLOW}Using credentials from config.yaml (for local development)${NC}"
        echo -e "${YELLOW}Note: For real AWS operations, configure AWS CLI with: aws configure${NC}"
    fi
else
    echo -e "${YELLOW}Using credentials from config.yaml${NC}"
    echo -e "${YELLOW}Note: Install AWS CLI and run 'aws configure' for real AWS operations${NC}"
fi

# Export AWS credentials (required for SAM CLI)
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_REGION

echo -e "${YELLOW}Setting AWS credentials...${NC}"
# Mask sensitive information in output
if [ "$AWS_ACCESS_KEY_ID" != "test" ]; then
    MASKED_KEY="${AWS_ACCESS_KEY_ID:0:8}****"
    echo "  AWS_ACCESS_KEY_ID=$MASKED_KEY"
else
    echo "  AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID (dummy for local dev)"
fi
echo "  AWS_SECRET_ACCESS_KEY=**** (hidden)"
echo "  AWS_REGION=$AWS_REGION"

# Check if Docker is running and accessible
echo -e "${YELLOW}Checking Docker availability...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running! Please start Docker Desktop.${NC}"
    exit 1
fi

# Set DOCKER_HOST for SAM CLI (required on macOS with Docker Desktop)
if [ -z "$DOCKER_HOST" ]; then
    # Check for Docker Desktop socket (macOS)
    if [ -S "$HOME/.docker/run/docker.sock" ]; then
        export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
    elif [ -S "/var/run/docker.sock" ]; then
        export DOCKER_HOST="unix:///var/run/docker.sock"
    fi
fi

# Quick test that Docker can list containers
if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is running but cannot access containers.${NC}"
    echo -e "${YELLOW}Please check Docker Desktop is fully started and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running and accessible${NC}"

# Check if docker-compose.yml exists
if [ ! -f "$PROJECT_ROOT/config/docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found!${NC}"
    echo -e "${YELLOW}Please create config/docker-compose.yml file${NC}"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose > /dev/null 2>&1 && ! docker compose version > /dev/null 2>&1; then
    echo -e "${RED}Error: docker-compose is not installed!${NC}"
    echo -e "${YELLOW}Please install docker-compose or use Docker Desktop which includes it${NC}"
    exit 1
fi

# Determine docker-compose command (docker-compose or docker compose)
if command -v docker-compose > /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    DOCKER_COMPOSE_CMD="docker compose"
fi

# Change to project root for docker-compose (it needs to be run from where docker-compose.yml is)
cd "$PROJECT_ROOT/config"

# Check if DynamoDB Local container exists (via docker directly, more reliable)
echo -e "${YELLOW}Checking DynamoDB Local container status...${NC}"

# First check if container exists and is running (direct docker check)
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}✓ DynamoDB Local container is already running${NC}"
    CONTAINER_RUNNING=true
elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    # Container exists but is stopped
    CONTAINER_STATE=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
    echo -e "${YELLOW}DynamoDB Local container exists but is in '$CONTAINER_STATE' state${NC}"
    
    if [ "$CONTAINER_STATE" = "exited" ] || [ "$CONTAINER_STATE" = "created" ]; then
        echo -e "${YELLOW}Starting existing container...${NC}"
        if docker start "$CONTAINER_NAME" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ DynamoDB Local container started${NC}"
            CONTAINER_RUNNING=true
        else
            echo -e "${YELLOW}Failed to start existing container, removing and recreating...${NC}"
            docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true
            CONTAINER_RUNNING=false
        fi
    else
        CONTAINER_RUNNING=false
    fi
else
    CONTAINER_RUNNING=false
fi

# If container is not running, check port and start it
if [ "$CONTAINER_RUNNING" != "true" ]; then
    # Check if port is in use by any process
    PORT_IN_USE_BY_PROCESS=false
    if lsof -ti:$DYNAMODB_PORT > /dev/null 2>&1; then
        PORT_IN_USE_BY_PROCESS=true
    fi
    
    # Check if another Docker container is using the port
    PORT_IN_USE_BY_CONTAINER=""
    # Check containers using host network mode
    HOST_NETWORK_CONTAINER=$(docker ps --filter "network=host" --format '{{.Names}}' | while read name; do
        docker inspect "$name" 2>/dev/null | grep -q "\"8000\"" && echo "$name" && break
    done 2>/dev/null)
    
    # Check containers with port mappings
    PORT_MAPPED_CONTAINER=$(docker ps --format '{{.Names}}' | while read name; do
        docker port "$name" 2>/dev/null | grep -q ":${DYNAMODB_PORT}" && echo "$name" && break
    done)
    
    # Check if our container is using the port (even if not detected as running)
    OUR_CONTAINER_USING_PORT=false
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        OUR_CONTAINER_USING_PORT=true
    fi
    
    if [ -n "$HOST_NETWORK_CONTAINER" ]; then
        if [ "$HOST_NETWORK_CONTAINER" = "$CONTAINER_NAME" ]; then
            # Our container is using the port - it's already running, skip
            echo -e "${GREEN}✓ DynamoDB Local container is already running (detected via port check)${NC}"
            CONTAINER_RUNNING=true
        else
            PORT_IN_USE_BY_CONTAINER="$HOST_NETWORK_CONTAINER"
        fi
    elif [ -n "$PORT_MAPPED_CONTAINER" ]; then
        if [ "$PORT_MAPPED_CONTAINER" = "$CONTAINER_NAME" ]; then
            # Our container is using the port - it's already running
            echo -e "${GREEN}✓ DynamoDB Local container is already running (detected via port check)${NC}"
            CONTAINER_RUNNING=true
        else
            PORT_IN_USE_BY_CONTAINER="$PORT_MAPPED_CONTAINER"
        fi
    fi
    
    # Handle port conflicts (only if container is not running)
    if [ "$CONTAINER_RUNNING" != "true" ] && [ -n "$PORT_IN_USE_BY_CONTAINER" ]; then
        echo -e "${RED}Error: Port $DYNAMODB_PORT is already in use by container '$PORT_IN_USE_BY_CONTAINER'${NC}"
        echo -e "${YELLOW}Please stop that container first: docker stop $PORT_IN_USE_BY_CONTAINER${NC}"
        echo -e "${YELLOW}Or use: ./shutdown.sh to clean up everything${NC}"
        exit 1
    fi
    
    if [ "$PORT_IN_USE_BY_PROCESS" = "true" ] && [ -z "$PORT_IN_USE_BY_CONTAINER" ]; then
        # Check if it's our container using the port
        if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo -e "${RED}Error: Port $DYNAMODB_PORT is already in use by a non-Docker process${NC}"
            echo -e "${YELLOW}Please free the port or change it in config.yaml${NC}"
            echo -e "${YELLOW}To find what's using the port: lsof -i:$DYNAMODB_PORT${NC}"
            exit 1
        fi
    fi
    
    # Start container using docker-compose (only if not already running)
    if [ "$CONTAINER_RUNNING" != "true" ]; then
        echo -e "${YELLOW}Starting DynamoDB Local container with docker-compose...${NC}"
        if ! $DOCKER_COMPOSE_CMD up -d dynamodb-local > /dev/null 2>&1; then
            echo -e "${RED}Error: Failed to start DynamoDB Local container${NC}"
            echo -e "${YELLOW}Check logs with: $DOCKER_COMPOSE_CMD logs dynamodb-local${NC}"
            exit 1
        fi
    fi
fi

# Wait for DynamoDB to be ready
echo -e "${YELLOW}Waiting for DynamoDB Local to be ready...${NC}"
sleep 2

# Check if container is running (use direct docker check, more reliable)
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    # Also check via docker-compose for better error message
    if ! $DOCKER_COMPOSE_CMD ps dynamodb-local 2>/dev/null | grep -q "Up"; then
        echo -e "${RED}Error: Failed to start DynamoDB Local container!${NC}"
        echo -e "${YELLOW}Check logs with: $DOCKER_COMPOSE_CMD logs dynamodb-local${NC}"
        echo -e "${YELLOW}Or check directly: docker logs $CONTAINER_NAME${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ DynamoDB Local is running on port $DYNAMODB_PORT${NC}"

# Wait for DynamoDB to be fully ready (it may take a moment to start)
echo -e "${YELLOW}Waiting for DynamoDB Local to be ready...${NC}"
MAX_RETRIES=10
RETRY_COUNT=0
DYNAMODB_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s "http://localhost:$DYNAMODB_PORT" > /dev/null 2>&1 || \
       docker exec "$CONTAINER_NAME" curl -s "http://localhost:8000" > /dev/null 2>&1; then
        DYNAMODB_READY=true
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 1
done

if [ "$DYNAMODB_READY" = true ]; then
    echo -e "${GREEN}✓ DynamoDB Local is ready${NC}"
else
    echo -e "${YELLOW}⚠ DynamoDB Local may not be fully ready, but continuing...${NC}"
    sleep 2  # Give it a bit more time
fi

# Always set up DynamoDB table (DynamoDB Local is in-memory, table is lost on container restart)
echo -e "${YELLOW}Setting up DynamoDB table...${NC}"
cd "$PROJECT_ROOT"
if [ -f "scripts/setup-table.js" ]; then
    if command -v node > /dev/null 2>&1; then
        if node scripts/setup-table.js; then
            echo -e "${GREEN}✓ DynamoDB table setup complete${NC}"
        else
            echo -e "${YELLOW}⚠ Table setup had issues (table may already exist)${NC}"
            echo -e "${YELLOW}  Continuing anyway...${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Node.js not found, skipping table setup${NC}"
        echo -e "${YELLOW}  Please run 'sam-util db-setup' manually after installing Node.js${NC}"
    fi
else
    echo -e "${YELLOW}⚠ setup-table.js not found, skipping table setup${NC}"
    echo -e "${YELLOW}  Please run 'sam-util db-setup' manually if needed${NC}"
fi

# Check for SAM template file
TEMPLATE_FILE=""
if [ -f "$PROJECT_ROOT/sam/template.yaml" ]; then
    TEMPLATE_FILE="$PROJECT_ROOT/sam/template.yaml"
elif [ -f "$PROJECT_ROOT/sam/template.yml" ]; then
    TEMPLATE_FILE="$PROJECT_ROOT/sam/template.yml"
else
    echo -e "${RED}Error: SAM template file not found!${NC}"
    echo -e "${YELLOW}Please create a template.yaml or template.yml file in sam/ directory${NC}"
    echo -e "${YELLOW}Or run: sam init to create a new SAM project${NC}"
    exit 1
fi

# Check SAM port availability before starting
echo -e "${YELLOW}Checking SAM port availability...${NC}"
SAM_PORT_IN_USE=false
SAM_PORT_PID=""
if lsof -ti:$SAM_PORT > /dev/null 2>&1; then
    SAM_PORT_IN_USE=true
    SAM_PORT_PID=$(lsof -ti:$SAM_PORT | head -1)
    SAM_PORT_USER=$(ps -p $SAM_PORT_PID -o comm= 2>/dev/null || echo "unknown")
    
    # Check if it's our SAM Local API process
    if ps aux | grep -q "[s]am local start-api"; then
        # Check if it's actually using this port
        if lsof -ti:$SAM_PORT | grep -q "$(pgrep -f 'sam local start-api' | head -1)"; then
            echo -e "${GREEN}✓ Port $SAM_PORT: SAM Local API is already running${NC}"
            echo -e "${YELLOW}If you want to restart, use: sam-util restart${NC}"
            echo -e "${YELLOW}Or stop it first: sam-util stop${NC}"
            exit 0
        fi
    fi
    
    # Port is in use by something else
    echo -e "${RED}Error: Port $SAM_PORT is already in use by $SAM_PORT_USER (PID: $SAM_PORT_PID)${NC}"
    echo -e "${YELLOW}Please free the port or change it in config.yaml${NC}"
    echo -e "${YELLOW}To find what's using the port: lsof -i:$SAM_PORT${NC}"
    echo -e "${YELLOW}To kill the process: kill $SAM_PORT_PID${NC}"
    echo -e "${YELLOW}Or use a different port in config/config.yaml: sam.port${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Port $SAM_PORT: Available for SAM Local API${NC}"
fi

# Build SAM arguments
SAM_ARGS="--port $SAM_PORT --warm-containers $WARM_CONTAINERS"
if [ -n "$DOCKER_NETWORK" ] && [ "$DOCKER_NETWORK" != "" ]; then
    SAM_ARGS="$SAM_ARGS --docker-network $DOCKER_NETWORK"
fi

echo -e "${YELLOW}Starting SAM Local API on port $SAM_PORT...${NC}"

# Verify SAM CLI can detect Docker before starting
echo -e "${YELLOW}Verifying SAM CLI can access Docker...${NC}"
if ! sam local invoke --help > /dev/null 2>&1; then
    echo -e "${RED}Error: SAM CLI is not working properly${NC}"
    exit 1
fi

# Test Docker connectivity for SAM (this is what SAM CLI checks)
if ! docker version > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker version check failed. SAM CLI requires Docker to be accessible.${NC}"
    echo -e "${YELLOW}Try: docker ps (to verify Docker is working)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ SAM Local API will be available at http://127.0.0.1:$SAM_PORT${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Detect project runtime from template
detect_runtime() {
    if [ -f "$PROJECT_ROOT/sam/template.yaml" ]; then
        TEMPLATE_FILE="$PROJECT_ROOT/sam/template.yaml"
    elif [ -f "$PROJECT_ROOT/sam/template.yml" ]; then
        TEMPLATE_FILE="$PROJECT_ROOT/sam/template.yml"
    else
        echo ""
        return
    fi
    
    # Extract runtime from template
    grep -i "Runtime:" "$TEMPLATE_FILE" | head -1 | sed 's/.*Runtime: *//' | sed 's/[^a-z0-9].*//' | tr '[:upper:]' '[:lower:]'
}

PROJECT_RUNTIME=$(detect_runtime)

# Copy dependencies to src/ based on runtime
if [ ! -d "$PROJECT_ROOT/src/node_modules" ]; then
    case "$PROJECT_RUNTIME" in
        nodejs*)
            if [ -d "$PROJECT_ROOT/node_modules" ]; then
                echo -e "${YELLOW}Copying node_modules to src/ for Lambda dependencies...${NC}"
                cp -r "$PROJECT_ROOT/node_modules" "$PROJECT_ROOT/src/" 2>/dev/null || {
                    echo -e "${RED}Warning: Failed to copy node_modules. Lambda may not have dependencies.${NC}"
                    echo -e "${YELLOW}Please run: cp -r node_modules src/${NC}"
                }
            else
                echo -e "${RED}Error: node_modules not found in project root!${NC}"
                echo -e "${YELLOW}Please run: npm install${NC}"
                echo -e "${YELLOW}Or run: sam-util verify (to check all prerequisites)${NC}"
                exit 1
            fi
            ;;
        python*)
            # Python dependencies are handled differently (no node_modules needed)
            if [ ! -f "$PROJECT_ROOT/requirements.txt" ]; then
                echo -e "${YELLOW}Warning: requirements.txt not found. Python dependencies may be missing.${NC}"
            fi
            ;;
        java*)
            # Java dependencies are handled via Maven/Gradle (no node_modules needed)
            if [ ! -f "$PROJECT_ROOT/pom.xml" ] && [ ! -f "$PROJECT_ROOT/build.gradle" ]; then
                echo -e "${YELLOW}Warning: pom.xml or build.gradle not found. Java dependencies may be missing.${NC}"
            fi
            ;;
        *)
            # Unknown runtime, try node_modules as fallback
            if [ -d "$PROJECT_ROOT/node_modules" ]; then
                echo -e "${YELLOW}Copying node_modules to src/ for Lambda dependencies...${NC}"
                cp -r "$PROJECT_ROOT/node_modules" "$PROJECT_ROOT/src/" 2>/dev/null || true
            fi
            ;;
    esac
fi

# Update template.yaml with DynamoDB endpoint from config (if host is configured)
if [ -n "$DYNAMODB_HOST" ]; then
    DYNAMODB_ENDPOINT="http://${DYNAMODB_HOST}:${DYNAMODB_PORT}"
    echo -e "${YELLOW}Using DynamoDB endpoint from config: $DYNAMODB_ENDPOINT${NC}"
    
    # Update template.yaml dynamically with the endpoint
    if [ -f "$TEMPLATE_FILE" ]; then
        # Create a temporary template with updated endpoint
        TEMP_TEMPLATE=$(mktemp)
        cp "$TEMPLATE_FILE" "$TEMP_TEMPLATE"
        
        # Update DYNAMODB_ENDPOINT in the template
        if grep -q "DYNAMODB_ENDPOINT:" "$TEMP_TEMPLATE"; then
            # Use sed to update the endpoint value
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS sed
                sed -i '' "s|DYNAMODB_ENDPOINT:.*|DYNAMODB_ENDPOINT: \"${DYNAMODB_ENDPOINT}\"|g" "$TEMP_TEMPLATE"
            else
                # Linux sed
                sed -i "s|DYNAMODB_ENDPOINT:.*|DYNAMODB_ENDPOINT: \"${DYNAMODB_ENDPOINT}\"|g" "$TEMP_TEMPLATE"
            fi
            TEMPLATE_FILE="$TEMP_TEMPLATE"
            echo -e "${GREEN}✓ Updated template with DynamoDB endpoint: $DYNAMODB_ENDPOINT${NC}"
        fi
    fi
fi

# Start SAM Local API (change back to project root)
cd "$PROJECT_ROOT"
sam local start-api --template "$TEMPLATE_FILE" $SAM_ARGS

# Clean up temporary template if created
if [ -n "$TEMP_TEMPLATE" ] && [ -f "$TEMP_TEMPLATE" ]; then
    rm -f "$TEMP_TEMPLATE"
fi

