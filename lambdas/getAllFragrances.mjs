import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";

// Initialize DynamoDB Client and DocumentClient
const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

const tableName = "FragrancePrices";

export const handler = async (event) => {
  console.log("Event received:", JSON.stringify(event, null, 2)); // Log the event for debugging

  try {
    const params = {
      TableName: tableName
    };

    console.log("Querying DynamoDB with params:", params); // Log query parameters

    const result = await dynamo.send(new ScanCommand(params));
    console.log("DynamoDB scan result:", result); // Log results from DynamoDB

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*", // CORS header
        "Content-Type": "application/json"
      },
      body: JSON.stringify(result.Items)
    };
  } catch (error) {
    console.error("Error fetching data:", error.message); // Log the error

    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*", // CORS header
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ error: "Internal Server Error", details: error.message })
    };
  }
};
