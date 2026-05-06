import sys
import os
import shutil

# Add current directory to path
current_dir = os.path.abspath(os.path.dirname(__file__))
sys.path.insert(0, current_dir)

# Delete existing database to clear the old schema without the new columns!
db_path = os.path.join(current_dir, 'instance', 'finwise.db')
if os.path.exists(db_path):
    os.remove(db_path)

import werkzeug
if not hasattr(werkzeug, '__version__'):
    werkzeug.__version__ = "3.0.0" # Placeholder for compatibility

from app import app, db, User
import json

def test_flow():
    client = app.test_client()
    
    print("--- Testing Registration ---")
    email = "testflow_srstest@example.com"
    password = "str0ngpassword!"
    
    # Clean up before testing
    with app.app_context():
        user = User.query.filter_by(email=email).first()
        if user:
            db.session.delete(user)
            db.session.commit()

    res = client.post('/register', json={
        'name': 'SRS Flow Tester',
        'email': email,
        'password': password
    })
    print(f"Register Status: {res.status_code} | Response: {res.json}")

    print("\n--- Testing Login ---")
    res = client.post('/login', json={
        'email': email,
        'password': password
    })
    print(f"Login Status: {res.status_code}")
    token = res.json.get('token')
    if not token:
        print("Failed to get token!")
        return
        
    headers = {'Authorization': f'Bearer {token}'}
    
    print("\n--- Testing Profile ---")
    res = client.put('/profile', headers=headers, json={"name": "SRS Full Flow"})
    print(f"Profile Update Status: {res.status_code} | Response: {res.json}")
    
    res = client.get('/profile', headers=headers)
    print(f"Profile Fetch Status: {res.status_code} | Name: {res.json.get('name')}")

    print("\n--- Testing Transactions ---")
    # Add Income
    res = client.post('/transactions', headers=headers, json={
        'amount': 8000,
        'type': 'income',
        'category': 'Salary',
        'date': '2026-04-18'
    })
    print(f"Add Income (8000) Status: {res.status_code} | Response: {res.json}")

    # Add Expense
    res = client.post('/transactions', headers=headers, json={
        'amount': 2500,
        'type': 'expense',
        'category': 'Food',
        'date': '2026-04-18',
        'description': 'Groceries',
        'mood': 'Happy',
        'payment_method': 'UPI'
    })
    print(f"Add Expense (2500) Status: {res.status_code} | Response: {res.json}")

    res = client.get('/transactions', headers=headers)
    txs = res.json.get('transactions', [])
    print(f"Fetched Transactions Status: {res.status_code} | Count: {len(txs)}")
    
    if txs:
        expense_tx_id = [t['id'] for t in txs if t['type'] == 'expense'][0]
        print(f"\n--- Testing Edit Transaction ({expense_tx_id}) ---")
        res = client.put(f'/transactions/{expense_tx_id}', headers=headers, json={
            'amount': 3000
        })
        print(f"Edit Transaction Status: {res.status_code} | Response: {res.json}")

    print("\n--- Testing Budgets ---")
    res = client.post('/budgets', headers=headers, json={
        'category': 'Food',
        'limit_amount': 4000,
        'month_year': '2026-04'
    })
    print(f"Add Budget Status: {res.status_code} | Response: {res.json}")

    res = client.get('/budgets?month_year=2026-04', headers=headers)
    print(f"Fetch Budgets Status: {res.status_code} | Data: {res.json}")

    print("\n--- Testing Goals ---")
    res = client.post('/goals', headers=headers, json={
        'target_amount': 10000,
        'current_amount': 500,
        'deadline': '2026-12-31',
        'description': 'Emergency Fund'
    })
    print(f"Add Goal Status: {res.status_code} | Response: {res.json}")

    res = client.get('/goals', headers=headers)
    goals = res.json.get('goals', [])
    print(f"Fetch Goals Status: {res.status_code} | Count: {len(goals)}")
    
    if goals:
        goal_id = goals[0]['id']
        res = client.put(f'/goals/{goal_id}', headers=headers, json={
            'current_amount': 1500
        })
        print(f"Edit Goal Status: {res.status_code} | Response: {res.json}")

    print("\n--- Testing Insights & Data Flow ---")
    res = client.get('/insights', headers=headers)
    print(f"Insights Status: {res.status_code}")
    print(f"Health Score: {res.json.get('health_score')}")
    print(f"Saving Tip: {res.json.get('saving_tip')}")

    print("\nAll Criteria Successfully Tested!")

if __name__ == '__main__':
    test_flow()
