# AWS SAM Local Development Setup

This project sets up AWS SAM Local with DynamoDB Local for local development and testing.

> **Quick Start:** See [QUICK_START.md](QUICK_START.md) for a condensed guide.

## Features

- **One-Command Project Setup** (`sams-util setup`) - Initialize projects with Node.js, Python, or Java
- **Global CLI Utility** (`sams-util`) - Manage SAM projects from anywhere
- **Comprehensive Help System** - Command-specific help for all features
- **Docker Compose** integration for DynamoDB Local
- **Automatic Script Creation** - All scripts created with executable permissions
- **Automatic table setup** on startup
- **AWS CLI credential integration** - Secure credential management
- **AWS Profile Support** - Deploy to different environments easily
- **One-Command Deployment** - Deploy to AWS with built-in validation
- **Configurable** via `config.yaml`

## Quick Start

### Prerequisites Installation

1. **Install AWS SAM CLI:**
   ```bash
   # macOS
   brew install aws-sam-cli
   
   # Verify installation
   sam --version  # Should show 1.100+
   ```

2. **Install Docker Desktop:**
   - Download from [docker.com](https://www.docker.com/products/docker-desktop)
   - Start Docker Desktop and ensure it's running
   - Verify: `docker --version`

3. **Install Node.js:**
   ```bash
   # macOS
   brew install node
   
   # Verify installation
   node --version  # Should show v18+ or v20+
   ```

4. **Verify Setup (Recommended):**
   ```bash
   # Run the verification script (based on aws-sam-runook guide)
   ./scripts/verify-setup.sh
   ```
   This will check all prerequisites and project files.

5. **Install dependencies (if using existing project):**
   ```bash
   # For Node.js projects
   npm install
   
   # For Python projects
   pip install -r requirements.txt
   
   # For Java projects
   mvn clean package
   ```
   
   > **Note:** If you're creating a new project, use `sams-util setup` which handles everything automatically.

### Initial Setup

**Option 1: Quick Setup (Recommended for new projects)**
```bash
# Initialize project with all required files (Node.js by default)
# This command automatically:
# 1. Creates all project files
# 2. Runs verification checks
# 3. Installs dependencies (npm/pip/mvn)
# 4. Starts services (DynamoDB Local + SAM Local API)
sams-util setup

# Or specify runtime:
sams-util setup --runtime nodejs   # Node.js (default)
sams-util setup --runtime python   # Python
sams-util setup --runtime java      # Java

# This creates:
# - config/docker-compose.yml
# - config/config.yaml.example
# - config/config.yaml
# - sam/template.yaml (runtime-specific)
# - src/app.js (Node.js) or src/app.py (Python) or src/main/java/... (Java)
# - package.json (Node.js) or requirements.txt (Python) or pom.xml (Java)
# - scripts/start.sh (executable)
# - scripts/shutdown.sh (executable)
# - scripts/verify-setup.sh (executable)
# - scripts/setup-table.js
# - .gitignore
#
# All scripts are automatically made executable - no chmod needed!
# Dependencies are automatically installed and services are started!
```

**Option 2: Manual Setup**
1. **Create configuration file:**
   ```bash
   # Copy the example config
   cp config/config.yaml.example config/config.yaml
   
   # Edit config/config.yaml if needed (defaults work for local development)
   ```

2. **Configure AWS CLI (for real AWS operations):**
   ```bash
   # Configure default profile
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Enter your default region (e.g., us-east-1)
   # Enter output format (json is recommended)
   
   # Or configure a named profile
   aws configure --profile myprofile
   
   # Verify configuration
   aws configure list
   aws sts get-caller-identity
   ```

3. **Install Global CLI Utility (Optional but Recommended):**
   ```bash
   # Install sams-util to use from any directory
   ./scripts/install-sams-util.sh
   
   # Follow the prompts to add to PATH if needed
   # Then you can use: sams-util start (from anywhere!)
   ```

4. **Start the environment:**
   ```bash
   # Option 1: Using global CLI (from any directory)
   # Note: sams-util start automatically runs verification and installs dependencies
   sams-util start
   
   # Option 2: Using local scripts (from project root)
   # Note: If using sams-util setup, scripts are already executable
   ./scripts/start.sh
   ```
   
   > **Note:** `sams-util start` automatically:
   > - Runs verification checks
   > - Installs missing dependencies (npm/pip/mvn)
   > - Starts DynamoDB Local
   > - Creates DynamoDB table
   > - Starts SAM Local API

5. **Test the API:**
   ```bash
   # Test the endpoint
   curl http://127.0.0.1:3000/hello
   # Expected: {"message":"DynamoDB Local works!"}
   ```

6. **Get Help (Anytime):**
   ```bash
   # General help
   sams-util help
   
   # Command-specific help
   sams-util help deploy      # Deployment guide
   sams-util help profile     # AWS profile setup
   sams-util <command> --help # Alternative syntax
   ```

7. **Shutdown:**
   ```bash
   ./scripts/shutdown.sh
   ```

## AWS Credential Management

This project uses **Option C: AWS CLI Configuration** for credential management.

### How It Works

1. **For Local Development (DynamoDB Local):**
   - Uses dummy credentials from `config.yaml` (`test`/`test`)
   - These are only used by SAM CLI, not for actual AWS operations
   - DynamoDB Local doesn't require real credentials

2. **For Real AWS Operations:**
   - AWS SDK automatically uses AWS CLI credentials
   - Configure with: `aws configure`
   - The script checks for AWS CLI credentials first
   - If found, uses them; otherwise falls back to `config.yaml`

### Credential Priority

The `start.sh` script uses credentials in this order:
1. **Environment variables** (if set)
2. **AWS CLI credentials** (from `~/.aws/credentials`)
3. **config.yaml** (for local development only)

### Security Best Practices

- ✅ **Never commit real credentials** to version control
- ✅ **Use dummy credentials** in `config.yaml` for local development
- ✅ **Use AWS CLI** for real AWS operations
- ✅ **Use IAM roles** in production (EC2, Lambda, ECS)
- ✅ **Rotate credentials** if accidentally exposed

## Configuration

### config.yaml

The `config/config.yaml` file contains all configuration for the local development environment.

#### Creating/Updating config.yaml

```bash
# Copy from example (first time)
cp config/config.yaml.example config/config.yaml

# Edit the file
nano config/config.yaml  # or use your preferred editor
```

#### Configuration Structure

```yaml
aws:
  # For local SAM development with DynamoDB Local, use dummy values
  # For real AWS operations, AWS SDK will use AWS CLI credentials automatically
  # Configure AWS CLI with: aws configure
  access_key_id: "test"      # Dummy for local dev (required by SAM CLI)
  secret_access_key: "test"  # Dummy for local dev (required by SAM CLI)
  region: "us-east-1"        # AWS region

dynamodb_local:
  image: "amazon/dynamodb-local"  # Docker image for DynamoDB Local
  port: 8000                      # Port for DynamoDB Local (host:container)
  container_name: "dynamodb-local" # Docker container name

sam:
  port: 3000                    # Port for SAM Local API
  warm_containers: "EAGER"      # Keep containers warm for faster response
  docker_network: "host"        # Use host network mode (set to "" to disable)
```

#### Configuration Options Explained

**AWS Section:**
- `access_key_id` / `secret_access_key`: Use `"test"` for local development. These are only used by SAM CLI, not for actual AWS API calls.
- `region`: AWS region (e.g., `us-east-1`, `us-west-2`). Used for AWS SDK initialization.

**DynamoDB Local Section:**
- `image`: Docker image name. Default: `amazon/dynamodb-local`
- `port`: Host port mapped to container port 8000. Change if 8000 is already in use.
- `container_name`: Name of the Docker container. Used for container management.

**SAM Section:**
- `port`: Port where SAM Local API will be accessible (default: 3000)
- `warm_containers`: 
  - `"EAGER"`: Keep containers warm (faster, uses more resources)
  - `"LAZY"`: Start containers on demand (slower, uses fewer resources)
- `docker_network`: 
  - `"host"`: Use host network mode (recommended for local development)
  - `""`: Use default bridge network

#### Using Different AWS Profiles

```bash
# Use a specific AWS CLI profile
export AWS_PROFILE=myprofile
./scripts/start.sh

# Or set it inline
AWS_PROFILE=myprofile ./scripts/start.sh

# Verify which profile is being used
aws configure list --profile myprofile
```

#### Environment Variables Override

You can override config values using environment variables:

```bash
# Override AWS credentials
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export AWS_REGION=us-west-2
./scripts/start.sh

# Override ports
export DYNAMODB_PORT=8001
export SAM_PORT=3001
./scripts/start.sh
```

## Global CLI Utility (sams-util)

The `sams-util` command provides a global CLI utility to manage SAM projects from **any directory** on your machine. No need to navigate to the project directory or copy files!

### Installation

```bash
# Install the utility (run from project root)
./scripts/install-sams-util.sh

# The installer will:
# 1. Copy sams-util to ~/.local/bin/
# 2. Make it executable
# 3. Check if ~/.local/bin is in your PATH
# 4. Offer to add it to your shell config if needed
```

**After installation**, you can use `sams-util` from anywhere:

```bash
# From your home directory
cd ~
sams-util start

# From any other directory
cd /some/other/path
sams-util status
```

### Commands

| Command | Description |
|---------|-------------|
| `sams-util start` | Start DynamoDB Local and SAM Local API (auto-verifies and installs dependencies) |
| `sams-util stop` | Stop all services and clean up |
| `sams-util restart` | Force restart (stop, verify, install dependencies, and start fresh) |
| `sams-util verify` | Verify setup and prerequisites |
| `sams-util db-setup [file]` | Set up DynamoDB table (optional file) |
| `sams-util deploy` | Deploy SAM application to AWS |
| `sams-util status` | Show status of running services |
| `sams-util setup [--runtime RUNTIME] [--force]` | Initialize project, verify, install dependencies, and start services (default: nodejs) |
| `sams-util help [command]` | Show help message or command-specific help |

### Usage Examples

```bash
# Start services (auto-detects project)
sams-util start

# Stop services
sams-util stop

# Restart everything
sams-util restart

# Verify setup
sams-util verify

# Set up DynamoDB table
sams-util db-setup

# Set up with specific file
sams-util db-setup scripts/custom-setup.js

# Deploy to AWS
sams-util deploy

# Deploy with specific AWS profile
sams-util --profile myprofile deploy

# Check status
sams-util status

# Use specific project directory
sams-util --project /path/to/project start

# Use specific config file
sams-util --config config/config.prod.yaml start

# Initialize new project (automatically verifies, installs dependencies, and starts services)
sams-util setup                   # Create Node.js project (default) - full auto-setup
sams-util setup --runtime python # Create Python project - full auto-setup
sams-util setup --runtime java   # Create Java project - full auto-setup
sams-util setup --force          # Overwrite existing files

# Get help
sams-util help                    # General help
sams-util help deploy             # Deployment guide
sams-util help profile            # Profile setup guide
sams-util help setup              # Setup command guide
sams-util deploy --help           # Same as: sams-util help deploy

### Project Detection

The utility automatically finds SAM projects by searching up the directory tree for:
- `sam/template.yaml` or `sam/template.yml`
- `config/config.yaml`

**Example:**
```bash
# You're in a subdirectory
cd ~/Documents/Learning-work/aws-sam-exp/src
sams-util start  # Still works! Auto-detects project root
```

### Options

- `--project DIR` - Specify project directory (default: auto-detect)
- `--config FILE` - Specify config file
- `--profile NAME` - Use specific AWS profile (see: `sams-util help profile`)
- `--help` - Show help message or command-specific help

### Getting Help

The utility provides comprehensive help for all commands and options:

```bash
# General help
sams-util help
sams-util --help

# Command-specific help
sams-util help deploy           # Detailed deployment guide
sams-util help profile          # AWS profile setup and usage
sams-util help start            # Start command details
sams-util help <command>        # Help for any command

# Alternative syntax
sams-util deploy --help         # Same as: sams-util help deploy
```

**Available help topics:**
- `sams-util help deploy` - Complete deployment guide with prerequisites
- `sams-util help profile` - How to set up and use AWS profiles
- `sams-util help setup` - Initialize project with runtime options (nodejs/python/java)
- `sams-util help start` - Local development setup
- `sams-util help <any-command>` - Detailed help for any command

### Benefits

✅ **Work from anywhere** - No need to `cd` to project directory  
✅ **Auto-detection** - Finds SAM projects automatically  
✅ **Multiple projects** - Manage different SAM projects easily  
✅ **Consistent interface** - Same commands for all projects  
✅ **Quick access** - No need to remember script paths  

## Deployment to AWS

### Prerequisites for Deployment

Before deploying to AWS, ensure:

1. **AWS CLI is configured** with valid credentials:
   ```bash
   aws configure
   # Or use a named profile
   aws configure --profile myprofile
   
   # Verify credentials
   aws sts get-caller-identity
   ```

2. **Update template for production**:
   - Remove or update `DYNAMODB_ENDPOINT` in `sam/template.yaml` (currently set to local endpoint)
   - For AWS DynamoDB, either:
     - Remove the `DYNAMODB_ENDPOINT` environment variable (uses AWS DynamoDB by default)
     - Or set it to your AWS DynamoDB table endpoint
   - Update Lambda code (`src/app.js`) to handle AWS DynamoDB (remove fake credentials)

3. **Create DynamoDB table in AWS** (if needed):
   ```bash
   # Create table using AWS CLI
   aws dynamodb create-table \
     --table-name TestTable \
     --attribute-definitions AttributeName=id,AttributeType=S \
     --key-schema AttributeName=id,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

### Deploying with sams-util

The easiest way to deploy:

```bash
# Basic deployment (uses default AWS profile)
sams-util deploy

# Deploy with specific AWS profile
sams-util --profile myprofile deploy
```

**What happens:**
1. ✅ Verifies AWS credentials are configured
2. ✅ Shows your AWS account information
3. ✅ Checks for local endpoints in template (warns if found)
4. ✅ Builds the SAM application
5. ✅ Runs `sam deploy --guided` (interactive deployment)

**During guided deployment**, you'll be asked:
- Stack name (e.g., `aws-sam-exp`)
- AWS Region (e.g., `us-east-1`)
- Confirm changes before deploy
- Allow SAM CLI IAM role creation
- Disable rollback on failure (optional)
- Save arguments to `samconfig.toml` (recommended)

### Manual Deployment

If you prefer manual control:

```bash
# 1. Build the application
sam build --template sam/template.yaml

# 2. Deploy (guided mode - interactive)
sam deploy --guided

# 3. Or deploy with existing config
sam deploy

# 4. Or deploy with specific parameters
sam deploy \
  --stack-name my-stack \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM \
  --confirm-changeset
```

### Post-Deployment

After successful deployment:

1. **Get the API endpoint**:
   ```bash
   # From CloudFormation outputs
   aws cloudformation describe-stacks \
     --stack-name <your-stack-name> \
     --query 'Stacks[0].Outputs'
   
   # Or check the SAM deployment output
   ```

2. **Test the deployed API**:
   ```bash
   # Replace with your actual API Gateway URL
   curl https://<api-id>.execute-api.us-east-1.amazonaws.com/Prod/hello
   ```

3. **View CloudFormation stack**:
   ```bash
   aws cloudformation describe-stacks --stack-name <your-stack-name>
   ```

### Updating Template for Production

**Before deploying**, update `sam/template.yaml`:

```yaml
# Remove or comment out the local endpoint
Environment:
  Variables:
    # DYNAMODB_ENDPOINT: "http://localhost:8000"  # Remove for production
    # Or set to your AWS DynamoDB table name
    DYNAMODB_TABLE_NAME: "TestTable"  # Use table name instead
```

**Update `src/app.js`** for production:

```javascript
// For AWS DynamoDB (production)
const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_REGION || 'us-east-1'
  // No endpoint = uses AWS DynamoDB
  // No fake credentials needed
});

// Use environment variable for table name
const TABLE_NAME = process.env.DYNAMODB_TABLE_NAME || 'TestTable';
```

### Troubleshooting Deployment

**Error: "No credentials found"**
```bash
# Configure AWS CLI
aws configure
# Or set environment variables
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

**Error: "Stack already exists"**
```bash
# Update existing stack
sam deploy

# Or delete and redeploy
aws cloudformation delete-stack --stack-name <stack-name>
# Wait for deletion, then deploy again
```

**Error: "Insufficient permissions"**
- Ensure your AWS credentials have permissions for:
  - CloudFormation (create/update stacks)
  - Lambda (create/update functions)
  - API Gateway (create/update APIs)
  - IAM (create roles - if using `--capabilities CAPABILITY_IAM`)

**Need more help?**
```bash
# Get detailed deployment help
sams-util help deploy

# Get help on using AWS profiles
sams-util help profile
```

## Scripts

### start.sh

Start DynamoDB Local and SAM Local API.

**Usage:**
```bash
./scripts/start.sh [OPTIONS] [CONFIG_FILE]
```

**Options:**
- `-r, --restart` - Force restart: stop and clean up existing services before starting
- `-s, --setup` - Automatically set up DynamoDB table after starting services
- `-c, --config FILE` - Specify a custom config file (default: `config.yaml`)
- `-h, --help` - Show help message

**Examples:**
```bash
# Normal start with default config/config.yaml
./scripts/start.sh

# Force restart (clean up and start fresh)
./scripts/start.sh --restart
./scripts/start.sh -r

# Restart and automatically set up DynamoDB table
./scripts/start.sh --restart --setup
./scripts/start.sh -r -s

# Use a custom config file
./scripts/start.sh --config config/config.prod.yaml
./scripts/start.sh config/custom-config.yaml

# Show help
./scripts/start.sh --help
```

**What it does:**
1. Parses configuration from `config.yaml`
2. Checks for AWS CLI credentials (uses them if available)
3. Verifies Docker is running
4. Checks if DynamoDB Local container exists and is running
5. Starts DynamoDB Local using docker-compose (if not running)
6. Automatically creates DynamoDB table (if `setup-table.js` exists)
7. Starts SAM Local API on the configured port
8. Sets up AWS credentials for SAM CLI

**Output:**
- Shows status of each step
- Displays which credentials are being used (masked for security)
- Provides the API endpoint URL when ready

### shutdown.sh

Stop all services and clean up containers.

**Usage:**
```bash
./scripts/shutdown.sh [CONFIG_FILE]
```

**What it does:**
1. Stops DynamoDB Local container
2. Removes DynamoDB Local container
3. Stops SAM Local API process (if running on configured port)
4. Cleans up all resources

**Example:**
```bash
# Shutdown with default config
./scripts/shutdown.sh

# Shutdown with custom config
./scripts/shutdown.sh config/config.prod.yaml
```

### setup-table.js

Create DynamoDB table in DynamoDB Local.

**Usage:**
```bash
node scripts/setup-table.js
```

**What it does:**
1. Connects to DynamoDB Local on `localhost:8000`
2. Checks if `TestTable` exists
3. Creates the table if it doesn't exist
4. Waits for table to be active

**Note:** This script is automatically run by `start.sh`, so you typically don't need to run it manually.

**Manual execution:**
```bash
# Only needed if you want to recreate the table manually
node scripts/setup-table.js
```

### verify-setup.sh

Verify all prerequisites and project setup (based on aws-sam-runook guide).

**Usage:**
```bash
./scripts/verify-setup.sh
```

**What it checks:**
1. SAM CLI installation and version (should be 1.100+)
2. Docker installation and running status
3. Node.js and npm installation
4. Project files (config, templates, Lambda code)
5. Dependencies installation status
6. Script permissions
7. AWS CLI configuration (optional)

**When to use:**
- Before first-time setup
- When troubleshooting issues
- After installing/updating prerequisites

**Note:** You can also use `sams-util verify` which does the same thing.

### sams-util

Global CLI utility for managing SAM projects from anywhere.

**Installation:**
```bash
./scripts/install-sams-util.sh
```

**Usage:**
```bash
# From any directory
sams-util <command> [options]

# Get help
sams-util help
sams-util help <command>
sams-util <command> --help
```

**See the "Global CLI Utility (sams-util)" section above for complete documentation.**
- To verify project is ready to run

**Example output:**
```bash
✓ SAM CLI installed: SAM CLI, version 1.146.0
✓ Docker installed: Docker version 24.0.7
✓ Node.js installed: v20.10.0
✓ All critical checks passed!
```

### Restart Procedures

#### Normal Restart
```bash
# Stop everything
./scripts/shutdown.sh

# Start again
./scripts/start.sh
```

#### Force Restart (Recommended)
```bash
# Clean up and restart in one command
./scripts/start.sh --restart
```

This will:
- Stop and remove existing DynamoDB Local container
- Kill any running SAM Local API processes
- Start everything fresh
- Automatically create the DynamoDB table

#### Restart with Table Setup
```bash
# Restart and ensure table is created
./scripts/start.sh --restart --setup
```

#### Troubleshooting Restart Issues

If you encounter port conflicts or container issues:

```bash
# 1. Force shutdown
./scripts/shutdown.sh

# 2. Check for remaining containers
docker ps -a | grep dynamodb-local

# 3. Manually remove if needed
docker rm -f dynamodb-local

# 4. Check for processes using ports
lsof -i:8000  # DynamoDB Local
lsof -i:3000   # SAM Local API

# 5. Kill processes if needed
kill $(lsof -ti:8000)  # Be careful with this!
kill $(lsof -ti:3000)  # Be careful with this!

# 6. Start fresh
./scripts/start.sh --restart
```

## Troubleshooting

### Setup Verification

If you encounter issues, first verify your setup:

```bash
# Run the verification script (based on aws-sam-runook guide)
./scripts/verify-setup.sh

# This will check:
# - SAM CLI installation and version (1.100+)
# - Docker installation and running status
# - Node.js and npm installation
# - Project files and configuration
# - Script permissions
# - Dependencies installation
```

**Common setup issues:**
- SAM CLI version too old → Update with `brew upgrade aws-sam-cli`
- Docker not running → Start Docker Desktop
- Missing dependencies → Run `npm install` (Node.js) or `pip install -r requirements.txt` (Python) or `mvn clean package` (Java)
- Scripts not executable → If using `sams-util setup`, scripts are automatically executable. Otherwise run `chmod +x scripts/*.sh`

**Getting help:**
```bash
# Get help for any command
sams-util help <command>

# Examples
sams-util help deploy    # Deployment guide
sams-util help profile   # AWS profile setup
sams-util help start     # Start command details
```

### Port Already in Use
```bash
# Check what's using the port
lsof -i:8000  # DynamoDB Local
lsof -i:3000  # SAM Local API

# Or use shutdown script
./scripts/shutdown.sh
```

### Container Issues
```bash
# Check container status
docker ps -a | grep dynamodb-local

# Check logs (from project root)
cd config && docker-compose logs dynamodb-local
# or
docker logs dynamodb-local
```

### AWS Credential Issues
```bash
# Verify AWS CLI is configured
aws configure list

# Test AWS CLI access
aws sts get-caller-identity
```

## Project Structure

```
aws-sam-exp/
├── src/                      # Lambda function source code
│   └── app.js               # Main Lambda handler
├── sam/                      # SAM template and related files
│   ├── template.yaml        # SAM template
│   └── test-event.json      # Test event for Lambda invocation
├── config/                   # Configuration files
│   ├── config.yaml          # Main configuration (use dummy credentials)
│   ├── config.yaml.example  # Example config template
│   └── docker-compose.yml   # DynamoDB Local Docker Compose config
├── scripts/                  # Utility scripts (all executable)
│   ├── start.sh             # Startup script (auto-created by setup)
│   ├── shutdown.sh          # Shutdown script (auto-created by setup)
│   ├── verify-setup.sh      # Setup verification script (auto-created by setup)
│   ├── setup-table.js       # DynamoDB table creation script
│   ├── sams-util            # Global CLI utility
│   └── install-sams-util.sh # Install sams-util globally
├── docs/                     # Documentation
│   └── aws-sam-runook.md    # Additional documentation
├── package.json             # Node.js dependencies (root only, not in src/)
├── requirements.txt          # Python dependencies (Python projects)
├── pom.xml                   # Maven configuration (Java projects)
├── package-lock.json        # Node.js lock file
├── README.md                # This file
└── .gitignore              # Git ignore rules
```

## Notes

- DynamoDB Local is **in-memory** - data is lost when container restarts
- Tables are **automatically created** on startup
- For production, use **IAM roles** instead of access keys
- The Lambda uses the host's IP address to connect to DynamoDB Local (configured in `template.yaml`)

