import os
import psycopg2

def init_db():
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("Error: DATABASE_URL environment variable is not set.")
        print("Please run this script from the Render Web Service Shell.")
        return

    print("Connecting to the database...")
    try:
        conn = psycopg2.connect(database_url)
        cur = conn.cursor()
        
        sql_files = ["schema.sql", "staff_schema.sql", "seed_extra.sql"]
        
        for file in sql_files:
            if os.path.exists(file):
                print(f"Executing {file}...")
                with open(file, 'r', encoding='utf-8') as f:
                    sql = f.read()
                    cur.execute(sql)
                conn.commit()
                print(f"Successfully executed {file}.")
            else:
                print(f"Warning: {file} not found. Skipping.")
                
        print("Database initialization complete! The system is ready.")
    except Exception as e:
        print(f"Failed to initialize database: {e}")
    finally:
        if 'conn' in locals() and conn:
            conn.close()

if __name__ == "__main__":
    init_db()
