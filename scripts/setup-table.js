const AWS = require('aws-sdk');

const dynamodb = new AWS.DynamoDB({
  endpoint: 'http://localhost:8000',
  region: 'us-east-1',
  accessKeyId: 'fake',
  secretAccessKey: 'fake'
});

const tableName = 'TestTable';

async function createTable() {
  try {
    // Check if table exists
    try {
      await dynamodb.describeTable({ TableName: tableName }).promise();
      console.log(`✓ Table '${tableName}' already exists`);
      return;
    } catch (err) {
      if (err.code !== 'ResourceNotFoundException') {
        throw err;
      }
    }

    // Create table
    const params = {
      TableName: tableName,
      AttributeDefinitions: [
        {
          AttributeName: 'id',
          AttributeType: 'S'
        }
      ],
      KeySchema: [
        {
          AttributeName: 'id',
          KeyType: 'HASH'
        }
      ],
      BillingMode: 'PAY_PER_REQUEST'
    };

    await dynamodb.createTable(params).promise();
    console.log(`✓ Table '${tableName}' created successfully`);
    
    // Wait for table to be active
    console.log('Waiting for table to be active...');
    await dynamodb.waitFor('tableExists', { TableName: tableName }).promise();
    console.log('✓ Table is now active');
    
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

createTable();

