#!/bin/bash

# Installation script for sam-util global CLI

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Installation directory
INSTALL_DIR="${HOME}/.local/bin"
BINARY_NAME="sam-util"

echo -e "${BLUE}Installing sam-util CLI...${NC}"
echo ""

# Check if sam-util script exists
if [ ! -f "$SCRIPT_DIR/sam-util" ]; then
    echo -e "${RED}Error: sam-util script not found at $SCRIPT_DIR/sam-util${NC}"
    exit 1
fi

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy script to install directory
cp "$SCRIPT_DIR/sam-util" "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

echo -e "${GREEN}✓ Installed sam-util to ${GREEN}$INSTALL_DIR/$BINARY_NAME${NC}"

# Check if install directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo -e "${YELLOW}⚠ $INSTALL_DIR is not in your PATH${NC}"
    echo ""
    
    # Detect shell
    SHELL_NAME=$(basename "$SHELL")
    CONFIG_FILE=""
    
    if [ "$SHELL_NAME" = "zsh" ]; then
        CONFIG_FILE="$HOME/.zshrc"
    elif [ "$SHELL_NAME" = "bash" ]; then
        CONFIG_FILE="$HOME/.bashrc"
    else
        CONFIG_FILE="$HOME/.profile"
    fi
    
    echo -e "${YELLOW}Add this to your $CONFIG_FILE:${NC}"
    echo -e "${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo ""
    echo -e "${YELLOW}Then run:${NC}"
    echo -e "${BLUE}source $CONFIG_FILE${NC}"
    echo ""
    
    # Offer to add it automatically
    read -p "Would you like to add it automatically? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$CONFIG_FILE" ]; then
            if ! grep -q "$INSTALL_DIR" "$CONFIG_FILE"; then
                echo "" >> "$CONFIG_FILE"
                echo "# Added by sam-util installer" >> "$CONFIG_FILE"
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$CONFIG_FILE"
                echo -e "${GREEN}✓ Added to $CONFIG_FILE${NC}"
                echo -e "${YELLOW}Run: source $CONFIG_FILE${NC}"
            else
                echo -e "${GREEN}✓ Already in $CONFIG_FILE${NC}"
            fi
        else
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" > "$CONFIG_FILE"
            echo -e "${GREEN}✓ Created $CONFIG_FILE${NC}"
            echo -e "${YELLOW}Run: source $CONFIG_FILE${NC}"
        fi
    fi
else
    echo -e "${GREEN}✓ $INSTALL_DIR is already in your PATH${NC}"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo "  sam-util --help              # Show help"
echo "  sam-util setup               # Initialize project, verify, install deps, and start (Node.js)"
echo "  sam-util setup --runtime python  # Initialize Python project (full auto-setup)"
echo "  sam-util setup --runtime java    # Initialize Java project (full auto-setup)"
echo "  sam-util start               # Start services (auto-verifies and installs deps)"
echo "  sam-util restart             # Restart services (auto-verifies and installs deps)"
echo "  sam-util stop                 # Stop services"
echo "  sam-util verify               # Verify setup manually"
echo "  sam-util deploy               # Deploy to AWS"
echo ""
echo -e "${YELLOW}For more commands, run:${NC} sam-util help"
echo ""
echo -e "${BLUE}Note:${NC} sam-util setup and start commands automatically:"
echo "  - Run verification checks"
echo "  - Install missing dependencies (npm/pip/mvn)"
echo "  - Start DynamoDB Local and SAM Local API"
echo "  - Create DynamoDB table"
echo ""


