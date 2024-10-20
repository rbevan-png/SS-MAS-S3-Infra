import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

// Initialize DynamoDB Client and DocumentClient
const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

// Set the DynamoDB table name
const tableName = "FragrancePrices";

export const handler = async (event) => {
  const fragranceData = {
    "Dior_Sauvage": [
      {
        "store_name": "Amazon",
        "site_link": "https://www.amazon.com/s?k=Sauvage&crid=28J6Y0MEHKMUS&sprefix=sauvage+%2Caps%2C161&ref=nb_sb_noss_2",
        "product_name": "Dior Sauvage Eau de Toilette Spray for Men",
        "bottle_size": "3.4 oz",
        "price": "$124.16"
      },
      {
        "store_name": "FragranceNet.com",
        "site_link": "https://www.fragrancenet.com/cologne/christian-dior/dior-sauvage/edt#283046",
        "product_name": "Dior Sauvage Eau De Toilette Spray Refillable",
        "bottle_size": "3.4 oz",
        "price": "$129.99"
      },
      {
        "store_name": "Perfumania",
        "site_link": "https://perfumania.com/search?q=Sauvage",
        "product_name": "Sauvage Eau de Toilette Spray for Men by Christian Dior",
        "bottle_size": "3.4 oz",
        "price": "$91.95"
      },
      {
        "store_name": "Sephora",
        "site_link": "https://www.sephora.com/search?keyword=Sauvage",
        "product_name": "DIOR Sauvage Eau de Toilette",
        "bottle_size": "3.4 oz",
        "price": "$112.00"
      },
      {
        "store_name": "FragranceX",
        "site_link": "https://www.fragrancex.com/search/search_results?stext=Sauvage+",
        "product_name": "Sauvage by Christian Dior",
        "bottle_size": "3.4 oz",
        "price": "$123.55"
      },
      {
        "store_name": "ThePerfumeSpot",
        "site_link": "https://theperfumespot.com/search-magic.html?query=Sauvage+&pu=null",
        "product_name": "Sauvage by Christian Dior Eau De Toilette Spray",
        "bottle_size": "6.8 oz",
        "price": "$178.35"
      },
      {
        "store_name": "Walmart",
        "site_link": "https://www.walmart.com/search?q=Sauvage+",
        "product_name": "Dior Sauvage Eau de Toilette, Cologne for Men",
        "bottle_size": "3.4 oz",
        "price": "$66.99"
      }
    ]
  };

  try {
    // Loop through each store and insert data into DynamoDB
    for (let store of fragranceData["Dior_Sauvage"]) {
      const params = {
        TableName: tableName,
        Item: {
          fragrance_name: "Dior_Sauvage",  // Partition key
          store_name: store.store_name,    // Sort key
          site_link: store.site_link,
          product_name: store.product_name,
          bottle_size: store.bottle_size,
          price: store.price
        }
      };

      // Execute the PutCommand to insert data
      await dynamo.send(new PutCommand(params));
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Fragrance data inserted successfully!" }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Failed to insert data", details: error.message }),
    };
  }
};
