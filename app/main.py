from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    fecha_hora = __import__('datetime').datetime.now()
    return {"message": "Hola Clase!", "fecha_hora": fecha_hora}

@app.get("/ping")
def ping():
    return {"status": "500"
