# Fragrance Data API with AWS Lambda and DynamoDB

This project provides a serverless REST API for storing and retrieving fragrance-related data using AWS Lambda and DynamoDB. The API supports multiple operations such as adding new fragrances, updating existing ones, and fetching stored data.

## Project Structure

- **`main.tf`**: Terraform configuration file that sets up the AWS infrastructure including DynamoDB, API Gateway, and Lambda functions.
- **`get.mjs`**: Lambda function to handle GET requests to fetch fragrance data from DynamoDB.
- **`seed.mjs`**: Lambda function to seed the DynamoDB table with initial fragrance data.
- **`updateFragrance.mjs`**: Lambda function to handle POST requests for adding or updating fragrance data in DynamoDB.
- **`getAllFragrances.mjs`**: Lambda function to handle GET requests to fetch all fragrance data from DynamoDB.
- **`package.json` & `package-lock.json`**: Node.js dependencies, including the AWS SDK.

## Requirements

- AWS account
- Terraform installed locally
- Node.js and npm installed

## Setup

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd <your-repo-folder>
```

### Step 2: Install Dependencies

Run the following command to install Node.js dependencies:

```bash
npm install
```

### Step 3: Initialize and Deploy Infrastructure Using Terraform

#### Initialize Terraform:

```bash
terraform init
```

#### Apply Terraform Plan

```bash
terraform apply --auto-approve
```

Terraform will create:

- A DynamoDB table named `FragrancePrices`
- Lambda functions for getting, seeding, and updating fragrance data
- An API Gateway for accessing the Lambda functions

### Step 4: Test API Endpoints

You can use tools like Postman or curl to test the following API endpoints:

#### Get Fragrance Data (GET Request)

**URL**: `/fragrances?fragrance_name=<fragrance_name>`

Example using curl (Postman also can be used):

```bash
curl -X GET "https://<api-gateway-url>/fragrances?fragrance_name=Dior_Sauvage"
```
#### Seed Fragrance Data (POST Request)

**URL**: `/fragrances`

This endpoint seeds the DynamoDB table with initial fragrance data.

#### Update Fragrance Data (POST Request)

**URL**: `/update-fragrance`

This endpoint allows you to add or update fragrance data in DynamoDB. The request body should contain the fragrance data in JSON format.

Example JSON body:

```json
{
  "Chanel_No_5": [
    {
      "store_name": "Amazon",
      "site_link": "https://www.amazon.com/Chanel-Women-Parfum-Spray-Ounce/dp/B000VOJ9BG",
      "product_name": "Chanel No. 5 Eau De Parfum",
      "bottle_size": "3.4 oz",
      "price": "$123.49"
    }
  ]
}
```


### Step 5: Destroy Infrastructure

When you're done, you can destroy the infrastructure by running:

```bash
terraform destroy

