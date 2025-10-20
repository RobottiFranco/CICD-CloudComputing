from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Hola Clase!"}

@app.get("/ping")
def ping():
    return {"status": "ok"}
