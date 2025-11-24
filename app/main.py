from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Security risk: Allows any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Security: Should not allow all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    fecha_hora = __import__('datetime').datetime.now()
    return {"message": "Hola Clase!", "fecha_hora": fecha_hora}

@app.get("/ping")
def ping():
    return {"status": "500"}
