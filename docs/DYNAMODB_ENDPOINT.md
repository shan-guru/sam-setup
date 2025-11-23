# DynamoDB Endpoint Configuration Guide

## Overview

This document explains how DynamoDB endpoint configuration works and why we use different approaches for different scenarios.

## Why Not Hard-Code IP Addresses?

**Problem:** Hard-coding IP addresses (like `192.168.50.13:8000`) causes issues when:
- IP addresses change (DHCP, network changes, different machines)
- Deploying to different environments
- Sharing projects across team members

**Solution:** Use dynamic endpoint detection based on network configuration.

## Network Modes and Endpoint Selection

### 1. Host Network Mode (Recommended for Local Development)

When using `--docker-network host`:
- **DynamoDB Local:** Runs on host network, accessible at `localhost:8000`
- **Lambda Container:** Also uses host network (via `--docker-network host`)
- **Endpoint:** `http://localhost:8000` ✅ **This works!**

**Why localhost works:**
- Both DynamoDB and Lambda containers share the host's network stack
- `localhost` in Lambda container = `localhost` on host = DynamoDB Local

**Configuration:**
```yaml
# config/config.yaml
sam:
  docker_network: "host"  # Enable host network mode

# sam/template.yaml
Environment:
  Variables:
    DYNAMODB_ENDPOINT: "http://localhost:8000"
```

### 2. Bridge Network Mode (Docker Desktop Default)

When NOT using host network:
- **DynamoDB Local:** Runs in bridge network, mapped to host port 8000
- **Lambda Container:** Runs in separate bridge network
- **Endpoint:** `http://host.docker.internal:8000` ✅ **Use this!**

**Why localhost doesn't work:**
- Lambda container's `localhost` ≠ host's `localhost`
- Containers are isolated in separate network namespaces
- `host.docker.internal` is a special DNS name Docker Desktop provides to reach the host

**Configuration:**
```yaml
# config/config.yaml
sam:
  docker_network: ""  # Use bridge network (default)

# sam/template.yaml
Environment:
  Variables:
    DYNAMODB_ENDPOINT: "http://host.docker.internal:8000"
```

### 3. Production Deployment

For AWS deployment:
- **Remove or comment out** `DYNAMODB_ENDPOINT` environment variable
- Lambda will use AWS DynamoDB service automatically
- No endpoint configuration needed

**Configuration:**
```yaml
# sam/template.yaml (for production)
Environment:
  Variables:
    # DYNAMODB_ENDPOINT: "http://localhost:8000"  # Commented out for AWS
```

## Current Implementation

### Template Configuration

The `sam/template.yaml` uses `localhost:8000` by default, which works when:
- `docker_network: "host"` is enabled in `config.yaml`
- DynamoDB Local is running with `network_mode: host` in `docker-compose.yml`

### Lambda Code

The Lambda code (`src/app.js`) has a fallback mechanism:
1. Uses `DYNAMODB_ENDPOINT` environment variable if set
2. Falls back to `http://localhost:8000` (works with host network)

### Setup Command

The `sams-util setup` command:
- Detects network configuration
- Sets appropriate endpoint in template
- Uses `localhost` when host network is enabled

## Troubleshooting

### Issue: "Cannot connect to DynamoDB Local"

**Check 1: Network Mode**
```bash
# Check DynamoDB container network
docker inspect dynamodb-local | grep NetworkMode

# Should show: "NetworkMode": "host"
```

**Check 2: SAM Network Mode**
```bash
# Check if SAM is using host network
ps aux | grep "sam local" | grep "docker-network"

# Should show: --docker-network host
```

**Check 3: Endpoint Configuration**
```bash
# Check template endpoint
grep DYNAMODB_ENDPOINT sam/template.yaml

# For host network: should be localhost:8000
# For bridge network: should be host.docker.internal:8000
```

### Solution: Force Host Network

If localhost isn't working:

1. **Ensure docker-compose uses host network:**
   ```yaml
   # config/docker-compose.yml
   services:
     dynamodb-local:
       network_mode: host
   ```

2. **Restart DynamoDB:**
   ```bash
   ./scripts/shutdown.sh
   ./scripts/start.sh
   ```

3. **Verify:**
   ```bash
   docker inspect dynamodb-local | grep NetworkMode
   # Should show: "NetworkMode": "host"
   ```

### Solution: Use host.docker.internal

If host network isn't available:

1. **Update template:**
   ```yaml
   # sam/template.yaml
   Environment:
     Variables:
       DYNAMODB_ENDPOINT: "http://host.docker.internal:8000"
   ```

2. **Restart SAM:**
   ```bash
   ./scripts/shutdown.sh
   ./scripts/start.sh
   ```

## Best Practices

1. **Use host network for local development** - Simplest and most reliable
2. **Use localhost endpoint** - Works with host network, no IP detection needed
3. **Don't hard-code IPs** - Causes issues across different machines/networks
4. **Override via environment variable** - Allows runtime configuration
5. **Remove endpoint for production** - Let AWS SDK use default DynamoDB service

## Summary

| Network Mode | DynamoDB Endpoint | Lambda Endpoint | Works? |
|--------------|------------------|-----------------|--------|
| Host Network | `localhost:8000` | `localhost:8000` | ✅ Yes |
| Bridge Network | `host:8000` (mapped) | `host.docker.internal:8000` | ✅ Yes |
| Bridge Network | `localhost:8000` | `localhost:8000` | ❌ No (different networks) |
| Production | (none - AWS service) | (none - AWS service) | ✅ Yes |

**Answer to your questions:**

1. **Why hard-code IP?** - We don't anymore! Now using `localhost` with host network.
2. **IP changes issue?** - Fixed by using `localhost` instead of hard-coded IP.
3. **Why localhost not working?** - It works with host network! The issue was DynamoDB container wasn't using host network. Now fixed.

