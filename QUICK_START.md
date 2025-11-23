# Quick Start Guide

## First Time Setup

**Quick Setup (Recommended):**
```bash
# 1. Initialize project (automatically verifies, installs dependencies, and starts services)
sam-util setup                    # Node.js (default) - does everything automatically!
# Or: sam-util setup --runtime python
# Or: sam-util setup --runtime java

# That's it! The setup command automatically:
# - Creates all project files
# - Runs verification checks
# - Installs dependencies (npm/pip/mvn)
# - Starts DynamoDB Local and SAM Local API
# - Creates DynamoDB table

# 2. (Optional) Install global CLI utility (if not already installed)
./scripts/install-sam-util.sh

# Note: All scripts are automatically created with executable permissions - no chmod needed!
# Note: Dependencies are automatically installed - no npm install needed!
# Note: Services are automatically started - no sam-util start needed!
```

**Manual Setup:**
```bash
# 1. Verify prerequisites (based on aws-sam-runook guide)
./scripts/verify-setup.sh

# 2. Install dependencies (runtime-specific)
# For Node.js:
npm install
# For Python:
pip install -r requirements.txt
# For Java:
mvn clean package

# 4. Create config file
cp config/config.yaml.example config/config.yaml

# 5. (Optional) Install global CLI utility
./scripts/install-sam-util.sh

# 6. Start the environment
./scripts/start.sh
# Or use: sam-util start (if installed)

# Note: If using sam-util setup, all scripts are created automatically with executable permissions
```

## Daily Usage

```bash
# Option 1: Using global CLI (from any directory)
# Note: sam-util start automatically verifies and installs dependencies
sam-util start      # Auto-verifies, installs deps, and starts services
sam-util stop       # Stop all services
sam-util restart    # Restart (auto-verifies and installs deps)
sam-util status     # Check service status

# Option 2: Using local scripts (from project root)
./scripts/start.sh
./scripts/shutdown.sh

# Test the API
curl http://127.0.0.1:3000/hello
```

## Common Commands

```bash
# Using global CLI (recommended)
sam-util setup             # Initialize project, verify, install deps, and start (Node.js default)
sam-util setup --runtime python  # Initialize Python project (full auto-setup)
sam-util setup --runtime java    # Initialize Java project (full auto-setup)
sam-util start             # Start services (auto-verifies and installs deps)
sam-util restart           # Force restart (auto-verifies and installs deps)
sam-util stop              # Stop all services
sam-util verify            # Verify setup manually
sam-util db-setup         # Set up DynamoDB table manually
sam-util deploy            # Deploy to AWS
sam-util status            # Check service status

# Getting help
sam-util help              # General help
sam-util help deploy       # Detailed deployment guide
sam-util help profile      # AWS profile setup guide
sam-util deploy --help     # Command-specific help

# Using local scripts
./scripts/start.sh --restart
./scripts/start.sh --restart --setup
./scripts/start.sh --help
```

## Getting Help

The `sam-util` command provides comprehensive help:

```bash
# General help menu
sam-util help
sam-util --help

# Command-specific help
sam-util help deploy       # Full deployment guide with prerequisites
sam-util help profile      # How to set up and use AWS profiles
sam-util help start        # Start command details
sam-util help <command>    # Help for any command

# Alternative syntax
sam-util deploy --help     # Same as: sam-util help deploy
```

**Help topics available:**
- `deploy` - Complete deployment guide, prerequisites, and examples
- `profile` - AWS profile setup, usage, and examples
- `setup` - Initialize project with runtime options (nodejs/python/java)
- `start`, `stop`, `restart`, `verify`, `db-setup`, `status` - Command details

## Setup Verification

Before starting, verify your setup (based on aws-sam-runook guide):

```bash
./scripts/verify-setup.sh
```

This checks:
- SAM CLI (version 1.100+)
- Docker (installed and running)
- Node.js and npm
- Project files and configuration
- Dependencies installation

## Project Structure

- `src/` - Lambda function code
- `sam/` - SAM templates and test events
- `config/` - Configuration files
- `scripts/` - Utility scripts (including verify-setup.sh)
- `docs/` - Documentation (including aws-sam-runook.md)

See [README.md](README.md) for detailed documentation.

