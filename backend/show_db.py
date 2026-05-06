import sqlite3
import json

conn = sqlite3.connect('instance/finwise.db')
conn.row_factory = sqlite3.Row
cur = conn.cursor()

# Get all tables
cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [r[0] for r in cur.fetchall()]
print('=' * 60)
print(f'TABLES FOUND: {tables}')
print('=' * 60)

for table in tables:
    cur.execute(f'SELECT * FROM {table}')
    rows = [dict(r) for r in cur.fetchall()]
    print(f'\n📋 TABLE: {table.upper()}  ({len(rows)} rows)')
    print('-' * 60)
    if rows:
        # Print column headers
        print(' | '.join(rows[0].keys()))
        print('-' * 60)
        for r in rows:
            print(json.dumps(r, default=str))
    else:
        print('  (empty)')

conn.close()
print('\n' + '=' * 60)
print('Done!')
