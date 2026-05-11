from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google import genai
import os
from dotenv import load_dotenv

# Load API Key mới
load_dotenv()
api_key = os.getenv("GOOGLE_AI_API_KEY")

client = None
if api_key:
    client = genai.Client(api_key=api_key)
    print("🚀 Đã sẵn sàng nhận API Key mới!")
else:
    print("⚠️ CẢNH BÁO: Hãy dán API Key mới vào file .env")

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

class ChatRequest(BaseModel):
    message: str
    context: str = ""

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    if not client:
        raise HTTPException(status_code=500, detail="API Key chưa được cập nhật trong .env")
    
    try:
        # gemini-flash-latest là bí danh luôn trỏ tới bản mới nhất đang chạy
        target_model = 'gemini-flash-latest'
        print(f"💬 Đang xử lý tin nhắn với Key mới (Model: {target_model})")
        
        prompt = f"Bạn là trợ lý AI của BadmintonApp. Ngữ cảnh: {request.context}\nCâu hỏi: {request.message}"
        
        response = client.models.generate_content(
            model=target_model, 
            contents=prompt
        )
        
        return {"response": response.text}
            
    except Exception as e:
        print(f"❌ LỖI: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
