import openai
import json
import os
from dotenv import load_dotenv
import re

# Load environment variables from .env file
load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")  # Set OpenAI API key from .env file

# Function to get the OpenAI API to filter JSON data based on criteria
def filter_fragrances_openai(json_data, query):
    # Updated prompt for flexible title matching with 3.4 oz / 100 ml size requirement
    prompt_message = f"""
    You are provided with a JSON array of fragrance products. Each product has fields like 'title', 'price', 'link', 'source', 'rating', 'reviews', 'thumbnail', and 'fragrance_id'. \
Please filter this list to include only products that slightly match the description '{query}'. Include only products that represent the same fragrance product in terms of brand, fragrance name, \
and type. For example, if it has Dior Sauvage Eau de Toilette then as long as you see Eau de Toilette then it's fine. So another valid example object would be Sauvage by Christian Dior Eau de Toilette Spray 3.4 oz. Additionally, only include products with a size of 3.4 oz or near it.

Return the filtered products in valid JSON array format, without additional text or explanations, so the JSON can be parsed directly.

    JSON Data:
    {json.dumps(json_data)}
    """

    messages = [
        {"role": "system", "content": "You are an assistant that helps filter JSON data based on product similarity and size criteria."},
        {"role": "user", "content": prompt_message}
    ]

    # Call the OpenAI API with the `gpt-3.5-turbo` model
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=messages,
        max_tokens=2048,
        temperature=0
    )

    # Extract and clean the response text
    response_text = response.choices[0].message['content'].strip()
    
    # Remove any Markdown code block delimiters if present
    response_text = re.sub(r"^```json|```$", "", response_text.strip())

    # Attempt to decode the cleaned response as JSON
    try:
        filtered_json = json.loads(response_text)
        return filtered_json
    except json.JSONDecodeError:
        print("Failed to decode JSON from OpenAI response.")
        print("Response received from OpenAI:", response_text)  # Print raw response for debugging
        return []

# Function to read JSON data from a file
def load_json_data(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        return json.load(f)

# Function to save filtered JSON data to a file
def save_filtered_data(filtered_data, output_filename):
    with open(output_filename, 'w', encoding='utf-8') as f:
        json.dump(filtered_data, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    # List of input JSON files
    input_files = ["Eros Flame Versace Men Eau De Parfum Spray 3.4 oz.json"]

    for input_file in input_files:
        # Load the JSON data
        json_data = load_json_data(input_file)
        
        # Use the input file name as the fragrance query, stripping out the file extension
        fragrance_query = input_file.replace(".json", "")
        
        # Use OpenAI API to filter the JSON data
        filtered_data = filter_fragrances_openai(json_data, fragrance_query)
        
        # Generate output filename by appending "filtered" to the input file name
        output_file = input_file.replace(".json", "_filtered.json")
        
        # Save the filtered data
        save_filtered_data(filtered_data, output_file)

        print(f"Filtered data saved to {output_file}")