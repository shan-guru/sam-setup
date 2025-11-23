# Quick Start Guide

## First Time Setup

**Quick Setup (Recommended):**
```bash
# 1. Initialize project (creates all required files)
sams-util setup                    # Node.js (default)
# Or: sams-util setup --runtime python
# Or: sams-util setup --runtime java

# 2. Install dependencies (runtime-specific)
# For Node.js:
npm install
# For Python:
pip install -r requirements.txt
# For Java:
mvn clean package

# 3. (Optional) Install global CLI utility
./scripts/install-sams-util.sh

# 4. Verify setup
sams-util verify

# 5. Start the environment
sams-util start

# Note: All scripts are automatically created with executable permissions - no chmod needed!
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
./scripts/install-sams-util.sh

# 6. Start the environment
./scripts/start.sh
# Or use: sams-util start (if installed)

# Note: If using sams-util setup, all scripts are created automatically with executable permissions
```

## Daily Usage

```bash
# Option 1: Using global CLI (from any directory)
sams-util start
sams-util stop
sams-util status

# Option 2: Using local scripts (from project root)
./scripts/start.sh
./scripts/shutdown.sh

# Test the API
curl http://127.0.0.1:3000/hello
```

## Common Commands

```bash
# Using global CLI (recommended)
sams-util restart          # Force restart
sams-util verify            # Verify setup
sams-util db-setup         # Set up DynamoDB table
sams-util deploy            # Deploy to AWS
sams-util status            # Check service status
sams-util setup             # Initialize Node.js project (default)
sams-util setup --runtime python  # Initialize Python project
sams-util setup --runtime java    # Initialize Java project

# Getting help
sams-util help              # General help
sams-util help deploy       # Detailed deployment guide
sams-util help profile      # AWS profile setup guide
sams-util deploy --help     # Command-specific help

# Using local scripts
./scripts/start.sh --restart
./scripts/start.sh --restart --setup
./scripts/start.sh --help
```

## Getting Help

The `sams-util` command provides comprehensive help:

```bash
# General help menu
sams-util help
sams-util --help

# Command-specific help
sams-util help deploy       # Full deployment guide with prerequisites
sams-util help profile      # How to set up and use AWS profiles
sams-util help start        # Start command details
sams-util help <command>    # Help for any command

# Alternative syntax
sams-util deploy --help     # Same as: sams-util help deploy
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

