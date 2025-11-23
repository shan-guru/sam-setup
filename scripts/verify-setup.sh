#!/bin/bash

# Setup verification script based on aws-sam-runook guide
# Verifies all prerequisites are installed and configured

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Verifying AWS SAM Local Setup...${NC}"
echo ""

ERRORS=0

# Check SAM CLI
echo -e "${YELLOW}Checking SAM CLI...${NC}"
if command -v sam > /dev/null 2>&1; then
    SAM_VERSION=$(sam --version 2>&1 | head -1)
    echo -e "${GREEN}✓ SAM CLI installed: $SAM_VERSION${NC}"
    
    # Check version (should be 1.100+)
    SAM_MAJOR=$(echo "$SAM_VERSION" | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
    SAM_MINOR=$(echo "$SAM_VERSION" | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f2)
    if [ "$SAM_MAJOR" -gt 1 ] || ([ "$SAM_MAJOR" -eq 1 ] && [ "$SAM_MINOR" -ge 100 ]); then
        echo -e "${GREEN}✓ SAM CLI version is 1.100+${NC}"
    else
        echo -e "${YELLOW}⚠ SAM CLI version should be 1.100+ (current: $SAM_VERSION)${NC}"
    fi
else
    echo -e "${RED}✗ SAM CLI not found!${NC}"
    echo -e "${YELLOW}  Install with: brew install aws-sam-cli${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check Docker
echo -e "${YELLOW}Checking Docker...${NC}"
if command -v docker > /dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version 2>&1)
    echo -e "${GREEN}✓ Docker installed: $DOCKER_VERSION${NC}"
    
    # Check if Docker is running
    if docker info > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker is running${NC}"
    else
        echo -e "${RED}✗ Docker is not running!${NC}"
        echo -e "${YELLOW}  Please start Docker Desktop${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}✗ Docker not found!${NC}"
    echo -e "${YELLOW}  Install Docker Desktop from docker.com${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Detect runtime from template
RUNTIME=""
TEMPLATE_FILE=""
if [ -f "sam/template.yaml" ]; then
    TEMPLATE_FILE="sam/template.yaml"
elif [ -f "sam/template.yml" ]; then
    TEMPLATE_FILE="sam/template.yml"
fi

if [ -n "$TEMPLATE_FILE" ]; then
    RUNTIME=$(grep -i "Runtime:" "$TEMPLATE_FILE" | head -1 | sed 's/.*Runtime: *//' | sed 's/[^a-z0-9].*//' | tr '[:upper:]' '[:lower:]')
fi

# Check runtime-specific dependencies
echo -e "${YELLOW}Checking runtime dependencies...${NC}"
case "$RUNTIME" in
    nodejs*)
        echo -e "${BLUE}Runtime detected: Node.js${NC}"
        if command -v node > /dev/null 2>&1; then
            NODE_VERSION=$(node --version 2>&1)
            echo -e "${GREEN}✓ Node.js installed: $NODE_VERSION${NC}"
        else
            echo -e "${RED}✗ Node.js not found!${NC}"
            echo -e "${YELLOW}  Install with: brew install node${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        
        if command -v npm > /dev/null 2>&1; then
            NPM_VERSION=$(npm --version 2>&1)
            echo -e "${GREEN}✓ npm installed: $NPM_VERSION${NC}"
        else
            echo -e "${RED}✗ npm not found!${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        
        # Check package.json and node_modules
        if [ -f "package.json" ]; then
            echo -e "${GREEN}✓ package.json found${NC}"
            if [ -d "node_modules" ]; then
                echo -e "${GREEN}✓ node_modules found (dependencies installed)${NC}"
            else
                echo -e "${RED}✗ node_modules not found!${NC}"
                echo -e "${YELLOW}  Installing dependencies with: npm install${NC}"
                if npm install; then
                    echo -e "${GREEN}✓ Dependencies installed successfully${NC}"
                else
                    echo -e "${RED}✗ Failed to install dependencies!${NC}"
                    echo -e "${YELLOW}  Please run: npm install${NC}"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
        else
            echo -e "${RED}✗ package.json not found!${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        ;;
    python*)
        echo -e "${BLUE}Runtime detected: Python${NC}"
        if command -v python3 > /dev/null 2>&1; then
            PYTHON_VERSION=$(python3 --version 2>&1)
            echo -e "${GREEN}✓ Python installed: $PYTHON_VERSION${NC}"
        else
            echo -e "${RED}✗ Python not found!${NC}"
            echo -e "${YELLOW}  Install Python 3.x${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        
        if [ -f "requirements.txt" ]; then
            echo -e "${GREEN}✓ requirements.txt found${NC}"
            # Check if dependencies are installed (basic check)
            if python3 -c "import boto3" 2>/dev/null; then
                echo -e "${GREEN}✓ boto3 installed${NC}"
            else
                echo -e "${YELLOW}⚠ boto3 not found in Python path${NC}"
                echo -e "${YELLOW}  Run: pip install -r requirements.txt${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ requirements.txt not found${NC}"
        fi
        ;;
    java*)
        echo -e "${BLUE}Runtime detected: Java${NC}"
        if command -v java > /dev/null 2>&1; then
            JAVA_VERSION=$(java -version 2>&1 | head -1)
            echo -e "${GREEN}✓ Java installed: $JAVA_VERSION${NC}"
        else
            echo -e "${RED}✗ Java not found!${NC}"
            echo -e "${YELLOW}  Install Java 11 or higher${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        
        if command -v mvn > /dev/null 2>&1; then
            MVN_VERSION=$(mvn --version 2>&1 | grep "Apache Maven" | head -1)
            echo -e "${GREEN}✓ Maven installed: $MVN_VERSION${NC}"
        else
            echo -e "${YELLOW}⚠ Maven not found (optional, but recommended for Java projects)${NC}"
        fi
        
        if [ -f "pom.xml" ]; then
            echo -e "${GREEN}✓ pom.xml found${NC}"
            # Basic check for build artifacts
            if [ -d "target" ]; then
                echo -e "${GREEN}✓ Java project built (target/ exists)${NC}"
            else
                echo -e "${YELLOW}⚠ Java project not built${NC}"
                echo -e "${YELLOW}  Run: mvn clean package${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ pom.xml not found${NC}"
        fi
        ;;
    *)
        if [ -z "$RUNTIME" ]; then
            echo -e "${YELLOW}⚠ Could not detect runtime from template${NC}"
        else
            echo -e "${YELLOW}⚠ Unknown runtime: $RUNTIME${NC}"
        fi
        # Fallback: check Node.js as default
        if command -v node > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Node.js available (fallback check)${NC}"
        fi
        ;;
esac
echo ""

# Check project files
echo -e "${YELLOW}Checking project files...${NC}"

# Check config file
if [ -f "config/config.yaml" ]; then
    echo -e "${GREEN}✓ config/config.yaml exists${NC}"
else
    echo -e "${YELLOW}⚠ config/config.yaml not found${NC}"
    echo -e "${YELLOW}  Create with: cp config/config.yaml.example config/config.yaml${NC}"
fi

# Check Lambda function
if [ -f "src/app.js" ]; then
    echo -e "${GREEN}✓ src/app.js exists${NC}"
else
    echo -e "${RED}✗ src/app.js not found!${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check SAM template
if [ -f "sam/template.yaml" ]; then
    echo -e "${GREEN}✓ sam/template.yaml exists${NC}"
else
    echo -e "${RED}✗ sam/template.yaml not found!${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Lambda source files (runtime-specific)
echo -e "${YELLOW}Checking Lambda source files...${NC}"
case "$RUNTIME" in
    nodejs*)
        if [ -f "src/app.js" ]; then
            echo -e "${GREEN}✓ src/app.js exists${NC}"
        else
            echo -e "${RED}✗ src/app.js not found!${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        # Note: node_modules will be copied from root by start.sh
        ;;
    python*)
        if [ -f "src/app.py" ]; then
            echo -e "${GREEN}✓ src/app.py exists${NC}"
        else
            echo -e "${RED}✗ src/app.py not found!${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        ;;
    java*)
        if [ -f "src/main/java/com/example/App.java" ]; then
            echo -e "${GREEN}✓ src/main/java/com/example/App.java exists${NC}"
        else
            echo -e "${RED}✗ Java Lambda source not found!${NC}"
            ERRORS=$((ERRORS + 1))
        fi
        ;;
    *)
        # Fallback: check for app.js
        if [ -f "src/app.js" ]; then
            echo -e "${GREEN}✓ src/app.js exists${NC}"
        else
            echo -e "${YELLOW}⚠ Lambda source file not found${NC}"
        fi
        ;;
esac
echo ""

# Check docker-compose.yml
if [ -f "config/docker-compose.yml" ]; then
    echo -e "${GREEN}✓ config/docker-compose.yml exists${NC}"
else
    echo -e "${RED}✗ config/docker-compose.yml not found!${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check scripts
if [ -f "scripts/start.sh" ] && [ -x "scripts/start.sh" ]; then
    echo -e "${GREEN}✓ scripts/start.sh exists and is executable${NC}"
else
    echo -e "${YELLOW}⚠ scripts/start.sh not found or not executable${NC}"
    echo -e "${YELLOW}  Fix with: chmod +x scripts/start.sh${NC}"
fi

if [ -f "scripts/shutdown.sh" ] && [ -x "scripts/shutdown.sh" ]; then
    echo -e "${GREEN}✓ scripts/shutdown.sh exists and is executable${NC}"
else
    echo -e "${YELLOW}⚠ scripts/shutdown.sh not found or not executable${NC}"
    echo -e "${YELLOW}  Fix with: chmod +x scripts/shutdown.sh${NC}"
fi

echo ""

# Check port availability
echo -e "${YELLOW}Checking port availability...${NC}"

# Read ports from config
if [ -f "config/config.yaml" ]; then
    read_yaml() {
        local section="$1"
        local key="$2"
        awk "/^${section}:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^  ${key}:/{print}" "config/config.yaml" | \
            sed 's/^  [^:]*: *//' | \
            sed 's/#.*$//' | \
            sed 's/^[[:space:]]*//' | \
            sed 's/[[:space:]]*$//' | \
            sed 's/^"\(.*\)"$/\1/' | \
            sed "s/^'\(.*\)'$/\1/" | \
            xargs
    }
    
    DYNAMODB_PORT=$(read_yaml "dynamodb_local" "port")
    SAM_PORT=$(read_yaml "sam" "port")
    
    # Check DynamoDB port
    if [ -n "$DYNAMODB_PORT" ]; then
        if lsof -ti:$DYNAMODB_PORT > /dev/null 2>&1; then
            PORT_PID=$(lsof -ti:$DYNAMODB_PORT | head -1)
            PORT_USER=$(ps -p $PORT_PID -o comm= 2>/dev/null || echo "unknown")
            if docker ps --format '{{.Names}}' | grep -q "dynamodb-local"; then
                echo -e "${GREEN}✓ Port $DYNAMODB_PORT: DynamoDB Local container${NC}"
            else
                echo -e "${YELLOW}⚠ Port $DYNAMODB_PORT: In use by $PORT_USER${NC}"
                echo -e "${YELLOW}  This may conflict with DynamoDB Local${NC}"
            fi
        else
            echo -e "${GREEN}✓ Port $DYNAMODB_PORT: Available for DynamoDB Local${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Could not read DynamoDB port from config${NC}"
    fi
    
    # Check SAM port
    if [ -n "$SAM_PORT" ]; then
        if lsof -ti:$SAM_PORT > /dev/null 2>&1; then
            PORT_PID=$(lsof -ti:$SAM_PORT | head -1)
            PORT_USER=$(ps -p $PORT_PID -o comm= 2>/dev/null || echo "unknown")
            PORT_CMD=$(ps -p $PORT_PID -o args= 2>/dev/null | head -c 80 || echo "unknown")
            
            # Check if it's SAM Local API
            if echo "$PORT_CMD" | grep -q "sam local start-api"; then
                echo -e "${GREEN}✓ Port $SAM_PORT: SAM Local API (already running)${NC}"
            elif ps aux | grep -q "[s]am local start-api"; then
                # SAM is running but might be on a different port
                echo -e "${YELLOW}⚠ Port $SAM_PORT: In use by $PORT_USER (PID: $PORT_PID)${NC}"
                echo -e "${YELLOW}  SAM Local API may be running on a different port${NC}"
                echo -e "${YELLOW}  This will conflict when starting SAM Local API${NC}"
                echo -e "${YELLOW}  To free the port: kill $PORT_PID${NC}"
                echo -e "${YELLOW}  Or stop SAM: sam-util stop${NC}"
            else
                echo -e "${RED}✗ Port $SAM_PORT: In use by $PORT_USER (PID: $PORT_PID)${NC}"
                echo -e "${YELLOW}  This will prevent SAM Local API from starting${NC}"
                echo -e "${YELLOW}  To free the port: kill $PORT_PID${NC}"
                echo -e "${YELLOW}  Or change port in config.yaml: sam.port${NC}"
                ERRORS=$((ERRORS + 1))
            fi
        else
            echo -e "${GREEN}✓ Port $SAM_PORT: Available for SAM Local API${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Could not read SAM port from config${NC}"
    fi
else
    echo -e "${YELLOW}⚠ config/config.yaml not found, cannot check ports${NC}"
fi
echo ""

# Check AWS CLI (optional but recommended)
echo -e "${YELLOW}Checking AWS CLI (optional for local dev)...${NC}"
if command -v aws > /dev/null 2>&1; then
    AWS_VERSION=$(aws --version 2>&1)
    echo -e "${GREEN}✓ AWS CLI installed: $AWS_VERSION${NC}"
    
    # Check if configured
    if aws configure list 2>/dev/null | grep -q "access_key"; then
        echo -e "${GREEN}✓ AWS CLI is configured${NC}"
    else
        echo -e "${YELLOW}⚠ AWS CLI not configured (optional for local dev)${NC}"
        echo -e "${YELLOW}  Configure with: aws configure${NC}"
    fi
else
    echo -e "${YELLOW}⚠ AWS CLI not installed (optional for local dev)${NC}"
    echo -e "${YELLOW}  Install with: brew install awscli${NC}"
fi
echo ""

# Summary
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo -e "${GREEN}You're ready to start the environment with: ./scripts/start.sh${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS critical issue(s)${NC}"
    echo -e "${YELLOW}Please fix the issues above before starting${NC}"
    exit 1
fi


