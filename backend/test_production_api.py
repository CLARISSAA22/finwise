import urllib.request
import json
import ssl

# Bypass SSL checks for python local request if needed (optional)
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

BASE_URL = "https://finwise-ived.onrender.com"

def run_test():
    print(f"[API TEST] Testing Deployed Production API at: {BASE_URL}")
    
    # 1. Test Base Database Endpoint
    try:
        req = urllib.request.Request(f"{BASE_URL}/fix-db", method="GET")
        with urllib.request.urlopen(req, context=ctx) as res:
            print(f"[OK] DB Status Code: {res.status} | Content: {res.read().decode().strip()[:100]}")
    except Exception as e:
        print(f"[ERROR] DB Check Failed: {e}")
        return

    # 2. Test Registration
    email = "live_tester_bca@example.com"
    password = "secure_password_99"
    name = "Live Cloud Tester"
    
    print("\n1. Testing Live Account Registration...")
    reg_data = json.dumps({"name": name, "email": email, "password": password}).encode("utf-8")
    req = urllib.request.Request(
        f"{BASE_URL}/register",
        data=reg_data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, context=ctx) as res:
            resp_body = json.loads(res.read().decode())
            print(f"[OK] Registration Success (Status: {res.status})")
            print(f"   Response: {resp_body}")
    except urllib.error.HTTPError as e:
        # Handle already exists gracefully
        if e.code == 400:
            print("User already exists in Neon database (continuing to login).")
        else:
            print(f"[ERROR] Registration Failed: {e.code} - {e.read().decode()}")
            return
    except Exception as e:
        print(f"[ERROR] Registration Connection Error: {e}")
        return

    # 3. Test Login
    print("\n2. Testing Live Account Login...")
    login_data = json.dumps({"email": email, "password": password}).encode("utf-8")
    req = urllib.request.Request(
        f"{BASE_URL}/login",
        data=login_data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, context=ctx) as res:
            resp_body = json.loads(res.read().decode())
            token = resp_body.get("token")
            print(f"[OK] Login Success (Status: {res.status})")
            print(f"   Received Token: {token[:20]}... [Valid]")
    except Exception as e:
        print(f"[ERROR] Login Failed: {e}")
        return

    # 4. Test adding an Income Transaction (Neon Write check)
    print("\n3. Testing Database Write (Adding Live Transaction)...")
    tx_data = json.dumps({
        "amount": 5000.0,
        "type": "income",
        "category": "Salary",
        "date": "2026-05-31",
        "description": "Production Live Verification Test",
        "mood": "Excited",
        "payment_method": "Internal"
    }).encode("utf-8")
    
    req = urllib.request.Request(
        f"{BASE_URL}/transactions",
        data=tx_data,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        },
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, context=ctx) as res:
            resp_body = json.loads(res.read().decode())
            print(f"[OK] DB Write Success (Status: {res.status})")
            print(f"   Response: {resp_body}")
    except Exception as e:
        print(f"[ERROR] DB Write Failed: {e}")
        return

    # 5. Test Fetching Transactions (Neon Read check)
    print("\n4. Testing Database Read (Fetching Live Transactions)...")
    req = urllib.request.Request(
        f"{BASE_URL}/transactions",
        headers={"Authorization": f"Bearer {token}"},
        method="GET"
    )
    
    try:
        with urllib.request.urlopen(req, context=ctx) as res:
            resp_body = json.loads(res.read().decode())
            txs = resp_body.get("transactions", [])
            print(f"[OK] DB Read Success (Status: {res.status})")
            print(f"   Fetched {len(txs)} transactions from Neon Database!")
            if txs:
                print(f"   Latest Transaction: {txs[0]['description']} (Amount: Rs.{txs[0]['amount']})")
    except Exception as e:
        print(f"[ERROR] DB Read Failed: {e}")
        return

    print("\nALL LIVE PRODUCTION END-TO-END TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    run_test()
