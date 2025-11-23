const AWS = require('aws-sdk');

// Determine DynamoDB configuration based on environment
// For local development: Uses DYNAMODB_ENDPOINT (DynamoDB Local)
// For production/AWS: No endpoint = uses AWS DynamoDB service
function getDynamoDBConfig() {
  const config = {
    region: process.env.AWS_REGION || 'us-east-1'
  };
  
  // If DYNAMODB_ENDPOINT is set, we're in local development mode
  if (process.env.DYNAMODB_ENDPOINT) {
    config.endpoint = process.env.DYNAMODB_ENDPOINT;
    // Use fake credentials for DynamoDB Local
    config.accessKeyId = 'fake';
    config.secretAccessKey = 'fake';
  }
  // If no endpoint, AWS SDK will use AWS DynamoDB service
  // Credentials will come from IAM role (Lambda execution role)
  
  return config;
}

const dynamodb = new AWS.DynamoDB.DocumentClient(getDynamoDBConfig());

// Helper function to create a valid API Gateway response
function createResponse(statusCode, body) {
  const response = {
    statusCode: statusCode,
    body: typeof body === 'string' ? body : JSON.stringify(body)
  };
  
  // Only add headers if needed (SAM Local might have issues with headers)
  // response.headers = {
  //   'Content-Type': 'application/json'
  // };
  
  return response;
}

exports.lambdaHandler = async (event) => {
  try {
    const tableName = process.env.DYNAMODB_TABLE_NAME || 'TestTable';
    const endpoint = process.env.DYNAMODB_ENDPOINT || 'AWS DynamoDB (production)';
    
    console.log('Lambda invoked, connecting to DynamoDB at:', endpoint);
    console.log('Using table:', tableName);
    
    // Quick test table
    await dynamodb.put({
      TableName: tableName,
      Item: { id: '1', name: 'Demo' }
    }).promise();

    console.log('Successfully wrote to DynamoDB');
    
    // Return simple response
    const isLocal = !!process.env.DYNAMODB_ENDPOINT;
    return {
      statusCode: 200,
      body: JSON.stringify({ 
        message: isLocal ? 'DynamoDB Local works!' : 'AWS DynamoDB works!',
        table: tableName,
        environment: isLocal ? 'local' : 'production'
      })
    };
  } catch (error) {
    console.error('Error:', error);
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    
    // Always return a valid response, even on error
    let errorBody = { message: 'Internal server error' };
    
    // Check if it's a ResourceNotFoundException (table doesn't exist)
    if (error.code === 'ResourceNotFoundException' || error.message.includes('Cannot do operations on a non-existent table')) {
      errorBody = { 
        message: 'Table does not exist',
        error: 'TestTable not found in DynamoDB Local. Please run ./setup-table.js to create it.'
      };
    } else if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND' || error.message.includes('connect')) {
      errorBody = { 
        message: 'Connection error',
        error: 'Cannot connect to DynamoDB',
        endpoint: process.env.DYNAMODB_ENDPOINT || 'AWS DynamoDB'
      };
    } else {
      errorBody = { 
        message: 'Internal server error',
        error: error.message || String(error),
        code: error.code || 'UNKNOWN',
        stack: error.stack,
        endpoint: process.env.DYNAMODB_ENDPOINT || 'AWS DynamoDB',
        type: error.constructor.name
      };
    }
    
    return {
      statusCode: 500,
      body: JSON.stringify(errorBody)
    };
  }
};