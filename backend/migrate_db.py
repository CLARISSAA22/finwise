import sqlite3
import os

db_path = 'instance/finwise.db'

if os.path.exists(db_path):
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("Mirroring database schema updates...")
        
        # Check if upi_id exists
        cursor.execute("PRAGMA table_info(user)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'upi_id' not in columns:
            print("Adding 'upi_id' column to 'user' table...")
            cursor.execute("ALTER TABLE user ADD COLUMN upi_id VARCHAR(100)")
            print("Successfully added 'upi_id' column.")
        else:
            print("'upi_id' column already exists.")
            
        cursor.execute("PRAGMA table_info(goal)")
        goal_columns = [column[1] for column in cursor.fetchall()]
        
        if 'auto_save_percentage' not in goal_columns:
            print("Adding 'auto_save_percentage' column to 'goal' table...")
            cursor.execute("ALTER TABLE goal ADD COLUMN auto_save_percentage FLOAT DEFAULT 0.0")
            print("Successfully added 'auto_save_percentage' column.")
        else:
            print("'auto_save_percentage' column already exists.")
            
        conn.commit()
        conn.close()
        print("Database migration complete.")
        
    except Exception as e:
        print(f"Migration error: {e}")
else:
    print("Database file not found. It will be created automatically on next run.")
