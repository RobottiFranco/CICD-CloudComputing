from fastapi import FastAPI
import sqlite3

app = FastAPI()

@app.get("/")
def root():
    fecha_hora = __import__('datetime').datetime.now()
    return {"message": "Hola Clase!", "fecha_hora": fecha_hora}

@app.get("/ping")
def ping():
    return {"status": "500"}

@app.get("/users/{user_id}")
def get_user(user_id: str):
    conn = sqlite3.connect('database.db')
    cursor = conn.cursor()
    
    # Security risk: SQL injection
    cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")  # Critical: SQL injection
    return cursor.fetchall()
