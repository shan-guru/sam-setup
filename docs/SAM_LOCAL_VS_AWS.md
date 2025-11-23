# SAM Local vs AWS - Understanding the Difference

## Is SAM Local Connecting to Live AWS?

**Short Answer: NO** ✅

SAM Local (`sam local start-api`, `sam local invoke`) runs **everything locally** on your machine. It does **NOT** connect to AWS services unless you explicitly deploy.

## What SAM Local Does

### Local Execution
- **Lambda Functions:** Run in Docker containers on your local machine
- **API Gateway:** Simulated locally (not real AWS API Gateway)
- **DynamoDB:** Uses DynamoDB Local (not AWS DynamoDB)
- **All Services:** Run in Docker containers, completely isolated from AWS

### What the "Billed Duration" Means

When you see:
```
REPORT RequestId: ... Duration: 10000.00 ms Billed Duration: 10000 ms
```

This is **NOT** actual AWS billing! It's just SAM Local reporting:
- **Simulated metrics** - Shows what the cost would be if deployed to AWS
- **No actual charges** - You're not being billed
- **Local execution** - Everything runs on your machine

## When Does It Connect to AWS?

SAM Local only connects to AWS when you:

1. **Deploy to AWS:**
   ```bash
   sam deploy --guided
   # or
   sams-util deploy
   ```
   This actually creates resources in your AWS account.

2. **Use AWS Services in Lambda Code:**
   - If your Lambda code calls AWS services (S3, DynamoDB, etc.)
   - And you have AWS credentials configured
   - The Lambda will make real AWS API calls
   - But this is from your Lambda code, not SAM Local itself

## Local Development Flow

```
┌─────────────────────────────────────┐
│  Your Local Machine                 │
│                                     │
│  ┌──────────────┐                   │
│  │ SAM Local    │                   │
│  │ (sam local)  │                   │
│  └──────┬───────┘                   │
│         │                            │
│  ┌──────▼───────┐  ┌─────────────┐ │
│  │ Lambda       │  │ DynamoDB    │ │
│  │ Container    │  │ Local       │ │
│  └──────────────┘  └─────────────┘ │
│                                     │
│  All running locally in Docker      │
└─────────────────────────────────────┘
         │
         │ (No connection to AWS)
         │
         ▼
    ┌─────────┐
    │  AWS    │
    │ (Cloud) │
    └─────────┘
```

## Production Deployment Flow

```
┌─────────────────────────────────────┐
│  Your Local Machine                 │
│                                     │
│  ┌──────────────┐                   │
│  │ SAM CLI      │                   │
│  │ (sam deploy) │                   │
│  └──────┬───────┘                   │
│         │                            │
│         │ Deploys via CloudFormation │
│         │                            │
└─────────┼────────────────────────────┘
          │
          ▼
    ┌─────────────────────────┐
    │  AWS Cloud              │
    │                         │
    │  ┌──────────────┐      │
    │  │ API Gateway  │      │
    │  └──────┬───────┘      │
    │         │               │
    │  ┌──────▼───────┐      │
    │  │ Lambda       │      │
    │  │ Function     │      │
    │  └──────┬───────┘      │
    │         │               │
    │  ┌──────▼───────┐      │
    │  │ DynamoDB     │      │
    │  │ (Real AWS)   │      │
    │  └──────────────┘      │
    └─────────────────────────┘
```

## Key Differences

| Aspect | SAM Local | AWS Deployment |
|--------|-----------|----------------|
| **Execution** | Local Docker containers | AWS Lambda |
| **API Gateway** | Simulated locally | Real AWS API Gateway |
| **DynamoDB** | DynamoDB Local | Real AWS DynamoDB |
| **Cost** | Free (local resources) | Pay per use |
| **Network** | Localhost/Docker | AWS VPC/Internet |
| **Credentials** | Optional (for AWS SDK calls) | Required |
| **Billing** | Simulated only | Real AWS billing |

## Credentials Usage

### SAM Local
- **For SAM CLI itself:** Uses dummy credentials (`test`/`test`) - just to satisfy SAM CLI
- **For Lambda code:** If your Lambda calls AWS services, it uses:
  - Environment variables (`AWS_ACCESS_KEY_ID`, etc.)
  - AWS CLI credentials (`~/.aws/credentials`)
  - IAM roles (if deployed to AWS)

### AWS Deployment
- **For deployment:** Requires real AWS credentials
- **For Lambda execution:** Uses IAM roles (no credentials in code)

## Summary

1. **SAM Local = 100% Local** - No AWS connection unless you deploy
2. **"Billed Duration" = Simulation** - Not real billing
3. **DynamoDB Local = Local Database** - Not AWS DynamoDB
4. **Deploy = Real AWS** - Only when you run `sam deploy`

**Your current setup:**
- ✅ Running locally
- ✅ No AWS connection
- ✅ No AWS charges
- ✅ Using DynamoDB Local (not AWS DynamoDB)

