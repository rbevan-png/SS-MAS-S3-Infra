from serpapi import GoogleSearch
import json
import re
import os
from dotenv import load_dotenv  # Import load_dotenv
import uuid  # To generate unique fragrance_id

# Load environment variables from .env file
load_dotenv()

# Function to check if the title contains most of the important keywords from the query
def is_relevant_title(title, query):
    # Extract important words from the query (e.g., 'Polo Blue Ralph Lauren Eau De Toilette')
    query_keywords = query.lower().split()
    
    title_lower = title.lower()

    # Check if at least half of the words from the query are present in the title
    match_count = sum(1 for word in query_keywords if word in title_lower)

    return match_count >= len(query_keywords) / 2  # Require at least half of the words to match

def get_fragrance_data(query):
    # Add the word 'fragrance' to the query to help improve accuracy
    query = f"{query} fragrance"
    
    params = {
        "engine": "google_shopping",
        "q": query,
        "hl": "en",
        "gl": "us",  # You can adjust/remove the location for more global searches
        "direct_link": "true",  # Include this parameter to get direct retailer links
        "api_key": os.getenv("SERPAPI_API_KEY")  # Retrieve API key from environment variable
    }

    search = GoogleSearch(params)
    results = search.get_dict()

    shopping_results = results.get('shopping_results', [])

    fragrances = []

    for idx, item in enumerate(shopping_results, start=1):
        title = item.get('title', '').lower()

        # Check if the title contains relevant keywords from the query
        if is_relevant_title(title, query):
            fragrance_info = {
                'fragrance_id': str(uuid.uuid4()),  # Generate a unique ID for each fragrance
                'title': item.get('title'),
                'price': item.get('price', 'Not Available'),  # Handle missing prices
                'link': item.get('link', 'N/A'),
                'source': item.get('source', 'Not Available'),  # Handle missing sources
                'rating': item.get('rating', 'Not Available'),  # Handle missing ratings
                'reviews': item.get('reviews', 'Not Available'),  # Handle missing reviews
                'thumbnail': item.get('thumbnail', 'N/A')  # Handle missing thumbnails
            }
            fragrances.append(fragrance_info)

    return fragrances

if __name__ == "__main__":
    fragrance_name = input("Enter the name of the fragrance: ")
    data = get_fragrance_data(fragrance_name)

    # Sanitize the fragrance name to create a valid filename
    sanitized_name = re.sub(r'[\\/*?:"<>|]', "", fragrance_name).strip()
    filename = f"{sanitized_name}.json"

    # Save the data to a JSON file
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print(f"Data saved to {filename}")