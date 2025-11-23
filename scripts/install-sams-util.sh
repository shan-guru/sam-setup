#!/bin/bash

# Installation script for sams-util global CLI

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
BINARY_NAME="sams-util"

echo -e "${BLUE}Installing sams-util CLI...${NC}"
echo ""

# Check if sams-util script exists
if [ ! -f "$SCRIPT_DIR/sams-util" ]; then
    echo -e "${RED}Error: sams-util script not found at $SCRIPT_DIR/sams-util${NC}"
    exit 1
fi

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy script to install directory
cp "$SCRIPT_DIR/sams-util" "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

echo -e "${GREEN}✓ Installed sams-util to ${GREEN}$INSTALL_DIR/$BINARY_NAME${NC}"

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
                echo "# Added by sams-util installer" >> "$CONFIG_FILE"
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
echo "  sams-util --help              # Show help"
echo "  sams-util setup               # Initialize new project (Node.js)"
echo "  sams-util setup --runtime python  # Initialize Python project"
echo "  sams-util setup --runtime java    # Initialize Java project"
echo "  sams-util start               # Start services"
echo "  sams-util stop                 # Stop services"
echo "  sams-util verify               # Verify setup"
echo "  sams-util deploy               # Deploy to AWS"
echo ""
echo -e "${YELLOW}For more commands, run:${NC} sams-util help"
echo ""


