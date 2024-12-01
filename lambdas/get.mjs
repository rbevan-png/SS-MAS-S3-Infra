import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";

// Initialize DynamoDB Client and DocumentClient
const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
  const fragranceName = event.queryStringParameters && event.queryStringParameters.fragrance_name;

  if (!fragranceName) {
    return {
      statusCode: 400,
      headers: {
        "Access-Control-Allow-Origin": "*", // CORS header
        "Access-Control-Allow-Headers": "Content-Type", // Optional for preflight
      },
      body: JSON.stringify({ error: "Fragrance name is required" }),
    };
  }

  try {
    // Query for items where fragrance_name matches the input
    const data = await dynamo.send(
      new QueryCommand({
        TableName: "FragrancePrices",
        KeyConditionExpression: "fragrance_name = :fragrance_name",
        ExpressionAttributeValues: {
          ":fragrance_name": fragranceName,
        },
      })
    );

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*", // CORS header
        "Access-Control-Allow-Headers": "Content-Type", // Optional for preflight
      },
      body: JSON.stringify(data.Items), // Return the matched items
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*", // CORS header
        "Access-Control-Allow-Headers": "Content-Type", // Optional for preflight
      },
      body: JSON.stringify({ error: "Could not retrieve data", details: error.message }),
    };
  }
};