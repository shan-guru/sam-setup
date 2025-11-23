#!/bin/bash

# Script to create DynamoDB table in DynamoDB Local

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DYNAMODB_ENDPOINT="http://localhost:8000"
TABLE_NAME="TestTable"

echo -e "${YELLOW}Setting up DynamoDB Local table...${NC}"

# Check if DynamoDB Local is running
if ! curl -s "$DYNAMODB_ENDPOINT" > /dev/null 2>&1; then
    echo -e "${RED}Error: DynamoDB Local is not running on $DYNAMODB_ENDPOINT${NC}"
    echo -e "${YELLOW}Please start DynamoDB Local first using ./start.sh${NC}"
    exit 1
fi

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo -e "${YELLOW}AWS CLI not found. Using curl to create table...${NC}"
    
    # Create table using DynamoDB Local API
    curl -X POST "$DYNAMODB_ENDPOINT" \
        -H "Content-Type: application/x-amz-json-1.0" \
        -H "X-Amz-Target: DynamoDB_20120810.CreateTable" \
        -d "{
            \"TableName\": \"$TABLE_NAME\",
            \"AttributeDefinitions\": [
                {
                    \"AttributeName\": \"id\",
                    \"AttributeType\": \"S\"
                }
            ],
            \"KeySchema\": [
                {
                    \"AttributeName\": \"id\",
                    \"KeyType\": \"HASH\"
                }
            ],
            \"BillingMode\": \"PAY_PER_REQUEST\"
        }" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Table '$TABLE_NAME' created successfully${NC}"
    else
        echo -e "${YELLOW}Table might already exist or there was an error${NC}"
    fi
else
    # Use AWS CLI if available
    echo -e "${YELLOW}Creating table using AWS CLI...${NC}"
    
    # Set fake credentials for DynamoDB Local
    export AWS_ACCESS_KEY_ID="fake"
    export AWS_SECRET_ACCESS_KEY="fake"
    
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=id,AttributeType=S \
        --key-schema AttributeName=id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --endpoint-url "$DYNAMODB_ENDPOINT" \
        --region us-east-1 > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Table '$TABLE_NAME' created successfully${NC}"
    else
        # Check if table already exists
        export AWS_ACCESS_KEY_ID="fake"
        export AWS_SECRET_ACCESS_KEY="fake"
        if aws dynamodb describe-table \
            --table-name "$TABLE_NAME" \
            --endpoint-url "$DYNAMODB_ENDPOINT" \
            --region us-east-1 > /dev/null 2>&1; then
            echo -e "${YELLOW}Table '$TABLE_NAME' already exists${NC}"
        else
            echo -e "${RED}Error: Failed to create table${NC}"
            exit 1
        fi
    fi
fi

echo -e "${GREEN}✓ DynamoDB Local setup complete${NC}"

