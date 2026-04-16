import os
import sys
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv("D:/Bosqen projects/yt_ summary_python/.env")
api_key = os.getenv("GEMINI_API_KEY")

if not api_key or api_key == "your_key_here":
    print("No valid API key found.")
    sys.exit()

genai.configure(api_key=api_key)

try:
    print("Available Models:")
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"- {m.name}")
except Exception as e:
    print(f"Error listing models: {e}")
