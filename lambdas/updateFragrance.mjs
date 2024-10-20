import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

// Initialize DynamoDB Client and DocumentClient
const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

// Set the DynamoDB table name
const tableName = "FragrancePrices";

export const handler = async (event) => {
  const requestData = JSON.parse(event.body);  // Parse the incoming JSON body

  // Extract the fragrance name from the request data
  const fragranceName = Object.keys(requestData)[0];
  const stores = requestData[fragranceName];

  try {
    // Loop through each store and insert or update data in DynamoDB
    for (let store of stores) {
      const params = {
        TableName: tableName,
        Item: {
          fragrance_name: fragranceName,  // Partition key (either add or update)
          store_name: store.store_name,   // Sort key
          site_link: store.site_link,
          product_name: store.product_name,
          bottle_size: store.bottle_size || "N/A",  // Default "N/A" if missing
          price: store.price
        }
      };

      // Execute the PutCommand to add or overwrite the item
      await dynamo.send(new PutCommand(params));
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Fragrance data added or updated successfully!" }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Failed to add or update data", details: error.message }),
    };
  }
};