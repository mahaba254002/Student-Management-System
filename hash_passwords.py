import psycopg2
from passlib.context import CryptContext
from dotenv import load_dotenv
import os

load_dotenv()

DB_CONFIG = {
    "host":     os.getenv("DB_HOST",     "localhost"),
    "database": os.getenv("DB_NAME",     "kwale_high_school"),
    "user":     os.getenv("DB_USER",     "postgres"),
    "password": os.getenv("DB_PASSWORD", ""),
    "port":     os.getenv("DB_PORT",     "5432"),
}

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_existing_passwords():
    print("Connecting to DB...")
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    cur.execute("SELECT id, password_hash FROM system_users")
    users = cur.fetchall()
    
    updated = 0
    for user_id, pwd in users:
        # Check if already hashed (bcrypt hashes usually start with $2b$ or $2a$)
        if pwd and not pwd.startswith("$2"):
            print(f"Hashing password for user {user_id}...")
            hashed = pwd_context.hash(pwd)
            cur.execute("UPDATE system_users SET password_hash = %s WHERE id = %s", (hashed, user_id))
            updated += 1
            
    conn.commit()
    conn.close()
    print(f"Updated {updated} passwords to bcrypt hashes.")

if __name__ == "__main__":
    hash_existing_passwords()
