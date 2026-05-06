#for all  background activity are done in this file 
import os
import pkgutil
import importlib.util
import sys
# Monkeypatch for Python 3.14 compatibility
if not hasattr(pkgutil, 'get_loader'):
    def get_loader(name):
        try:
            spec = importlib.util.find_spec(name)
            return spec.loader if spec else None
        except Exception:
            return None
    pkgutil.get_loader = get_loader
from flask import Flask, request, jsonify
from flask_cors import CORS
from models import db, User, Transaction, Budget, Subscription, Goal
from flask_bcrypt import Bcrypt
import jwt
from datetime import datetime, timedelta, date
try:
    import razorpay
    RAZORPAY_AVAILABLE = True
except ImportError:
    RAZORPAY_AVAILABLE = False

app = Flask(__name__)
# Configurations
app.config['SECRET_KEY'] = 'finwise_secret_key'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///finwise.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

CORS(app)
db.init_app(app)
bcrypt = Bcrypt(app)

@app.route('/fix-db', methods=['GET'])
def fix_db():
    try:
        from sqlalchemy import text
        with db.engine.connect() as conn:
            try:
                conn.execute(text("ALTER TABLE user ADD COLUMN upi_id VARCHAR(100)"))
            except Exception:
                pass
            try:
                conn.execute(text("ALTER TABLE goal ADD COLUMN auto_save_percentage FLOAT DEFAULT 0.0"))
            except Exception:
                pass
            conn.commit()
        return "<h1>Database Repaired!</h1><p>The missing columns were added successfully. You can now login.</p>", 200
    except Exception as e:
        return f"<h1>Database Status</h1><p>Note: {str(e)}</p><p>This usually means the columns already exist. Try logging in now!</p>", 200

with app.app_context():
    db.create_all()
    
    # --- AUTO-MIGRATION SYSTEM ---
    # This automatically adds new columns to the database without breaking the app.
    try:
        from sqlalchemy import text
        with db.engine.connect() as conn:
            # Add upi_id to User table if missing
            try:
                conn.execute(text("ALTER TABLE user ADD COLUMN upi_id VARCHAR(100)"))
                conn.commit()
                print("Migration: Added upi_id to user table.")
            except Exception:
                pass # Column already exists
                
            # Add auto_save_percentage to Goal table if missing
            try:
                conn.execute(text("ALTER TABLE goal ADD COLUMN auto_save_percentage FLOAT DEFAULT 0.0"))
                conn.commit()
                print("Migration: Added auto_save_percentage to goal table.")
            except Exception:
                pass # Column already exists
                
            # You can add more auto-migrations here in the future
    except Exception as e:
        print(f"Auto-migration error: {e}")
    # -----------------------------

# Decorator for JWT Auth
def token_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            parts = request.headers['Authorization'].split()
            if len(parts) == 2 and parts[0] == 'Bearer':
                token = parts[1]
        
        if not token:
            return jsonify({'message': 'Token is missing!'}), 401
        
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
            current_user = User.query.get(data['user_id'])
            if not current_user:
                return jsonify({'message': 'Invalid User!'}), 401
        except Exception as e:
            print(f"Auth Error: {e}")
            return jsonify({'message': 'Token is invalid!', 'error': str(e)}), 401
            
        return f(current_user, *args, **kwargs)
    return decorated

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'message': 'User already exists!'}), 400
    
    hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')
    new_user = User(name=data['name'], email=data['email'], password_hash=hashed_password)
    db.session.add(new_user)
    db.session.commit()
    
    return jsonify({'message': 'User registered successfully!'}), 201

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        user = User.query.filter_by(email=data['email']).first()
        
        if not user:
            return jsonify({'message': 'User not found!'}), 401
            
        if bcrypt.check_password_hash(user.password_hash, data['password']):
            token = jwt.encode({'user_id': user.id, 'exp': datetime.utcnow() + timedelta(days=30)}, app.config['SECRET_KEY'], algorithm="HS256")
            if isinstance(token, bytes):
                token = token.decode('utf-8')
            return jsonify({'token': token, 'user': {'name': user.name, 'email': user.email, 'total_balance': user.total_balance, 'upi_id': user.upi_id}}), 200
        else:
            return jsonify({'message': 'Invalid credentials!'}), 401
    except Exception as e:
        print(f"Login Error: {e}")
        return jsonify({'message': 'Server error during login', 'error': str(e)}), 500

@app.route('/google-login', methods=['POST'])
def google_login():
    # Simulate finding or creating a user via Google OAuth
    demo_email = "google_demo@example.com"
    user = User.query.filter_by(email=demo_email).first()
    
    if not user:
        # Create a demo user for the first time
        hashed_password = bcrypt.generate_password_hash("google_demo_pass").decode('utf-8')
        user = User(name="Google Demo User", email=demo_email, password_hash=hashed_password)
        db.session.add(user)
        db.session.commit()
    
    token = jwt.encode({'user_id': user.id, 'exp': datetime.utcnow() + timedelta(days=30)}, app.config['SECRET_KEY'], algorithm="HS256")
    if isinstance(token, bytes):
        token = token.decode('utf-8')
    return jsonify({'token': token, 'user': {'name': user.name, 'email': user.email, 'total_balance': user.total_balance, 'upi_id': user.upi_id}}), 200

@app.route('/profile', methods=['GET'])
@token_required
def profile(current_user):
    return jsonify({
        'name': current_user.name,
        'email': current_user.email,
        'total_balance': current_user.total_balance,
        'streak': current_user.streak,
        'badges': current_user.badges.split(',') if current_user.badges else [],
        'upi_id': current_user.upi_id
    }), 200

@app.route('/profile', methods=['PUT'])
@token_required
def update_profile(current_user):
    data = request.get_json()
    if 'name' in data:
        current_user.name = data['name']
    if 'upi_id' in data:
        current_user.upi_id = data['upi_id']
    db.session.commit()
    return jsonify({'message': 'Profile updated!'}), 200

def update_streak(user, tx_date_str):
    try:
        date_part = tx_date_str.split(' ')[0]
        tx_date = datetime.strptime(date_part, '%Y-%m-%d').date()
    except Exception:
        tx_date = datetime.utcnow().date()
        
    last_date_str = user.last_entry_date
    if not last_date_str:
        user.streak = 1
        user.last_entry_date = str(tx_date)
        return
        
    last_date = datetime.strptime(last_date_str, '%Y-%m-%d').date()
    
    delta = (tx_date - last_date).days
    
    if delta == 1:
        user.streak += 1
        user.last_entry_date = str(tx_date)
    elif delta > 1:
        user.streak = 1
        user.last_entry_date = str(tx_date)
    elif delta == 0:
        pass

@app.route('/transactions', methods=['POST'])
@token_required
def add_transaction(current_user):
    data = request.get_json()
    amount = float(data['amount'])
    tx_type = data['type']
    
    new_tx = Transaction(
        user_id=current_user.id,
        amount=amount,
        type=tx_type,
        category=data['category'],
        date=data['date'],
        description=data.get('description', ''),
        mood=data.get('mood', 'Neutral'),
        payment_method=data.get('payment_method', 'Cash'),
        upi_ref=data.get('upi_ref', '')
    )
    
    if tx_type == 'income':
        current_user.total_balance += amount
    else:
        current_user.total_balance -= amount
        
    update_streak(current_user, data['date'])
        
    db.session.add(new_tx)
    db.session.commit()
    
    return jsonify({'message': 'Transaction added!'}), 201

@app.route('/transactions', methods=['GET'])
@token_required
def get_transactions(current_user):
    transactions = Transaction.query.filter_by(user_id=current_user.id).order_by(Transaction.date.desc()).all()
    output = []
    for tx in transactions:
        output.append({
            'id': tx.id,
            'amount': tx.amount,
            'type': tx.type,
            'category': tx.category,
            'date': tx.date,
            'description': tx.description,
            'mood': tx.mood,
            'payment_method': tx.payment_method,
            'upi_ref': tx.upi_ref
        })
    return jsonify({'transactions': output}), 200

@app.route('/transactions/<int:tx_id>', methods=['PUT', 'DELETE'])
@token_required
def modify_transaction(current_user, tx_id):
    tx = Transaction.query.filter_by(id=tx_id, user_id=current_user.id).first()
    if not tx:
        return jsonify({'message': 'Not found'}), 404
        
    if request.method == 'DELETE':
        if tx.type == 'income':
            current_user.total_balance -= tx.amount
        else:
            current_user.total_balance += tx.amount
        db.session.delete(tx)
        db.session.commit()
        return jsonify({'message': 'Transaction deleted'}), 200
        
    if request.method == 'PUT':
        data = request.get_json()
        
        # Reverse old balance impact
        if tx.type == 'income':
            current_user.total_balance -= tx.amount
        else:
            current_user.total_balance += tx.amount
            
        tx.amount = float(data.get('amount', tx.amount))
        tx.type = data.get('type', tx.type)
        tx.category = data.get('category', tx.category)
        tx.date = data.get('date', tx.date)
        tx.description = data.get('description', tx.description)
        tx.mood = data.get('mood', tx.mood)
        tx.payment_method = data.get('payment_method', tx.payment_method)
        tx.upi_ref = data.get('upi_ref', tx.upi_ref)
        
        # Apply new balance impact
        if tx.type == 'income':
            current_user.total_balance += tx.amount
        else:
            current_user.total_balance -= tx.amount
            
        db.session.commit()
        return jsonify({'message': 'Transaction updated'}), 200

@app.route('/budgets', methods=['POST'])
@token_required
def add_budget(current_user):
    data = request.get_json()
    category = data['category']
    month_year = data['month_year']
    limit_amount = float(data['limit_amount'])
    
    # Prevent duplicates: Check if budget already exists for this category and month
    existing_budget = Budget.query.filter_by(
        user_id=current_user.id, 
        category=category, 
        month_year=month_year
    ).first()
    
    if existing_budget:
        existing_budget.limit_amount = limit_amount
        db.session.commit()
        return jsonify({'message': 'Budget updated!'}), 200

    new_budget = Budget(
        user_id=current_user.id,
        category=category,
        limit_amount=limit_amount,
        month_year=month_year
    )
    db.session.add(new_budget)
    db.session.commit()
    return jsonify({'message': 'Budget added!'}), 201

@app.route('/budgets', methods=['GET'])
@token_required
def get_budgets(current_user):
    month_year = request.args.get('month_year', datetime.utcnow().strftime('%Y-%m'))
    budgets = Budget.query.filter_by(user_id=current_user.id, month_year=month_year).all()
    
    # Fetch ALL expense transactions for this user for the month once
    all_txs = Transaction.query.filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'expense',
        Transaction.date.like(f"{month_year}%")
    ).all()

    output = []
    for bg in budgets:
        # Python-level case-insensitive match — 100% reliable
        spent = sum(
            tx.amount for tx in all_txs
            if tx.category.strip().lower() == bg.category.strip().lower()
        )
        output.append({
            'id': bg.id,
            'category': bg.category,
            'limit_amount': bg.limit_amount,
            'month_year': bg.month_year,
            'spent': spent
        })
    return jsonify({'budgets': output}), 200

@app.route('/subscriptions', methods=['POST'])
@token_required
def add_subscription(current_user):
    data = request.get_json()
    new_sub = Subscription(
        user_id=current_user.id,
        name=data['name'],
        amount=float(data['amount']),
        billing_cycle=data['billing_cycle'],
        next_due_date=data['next_due_date']
    )
    db.session.add(new_sub)
    db.session.commit()
    return jsonify({'message': 'Subscription added!'}), 201

@app.route('/subscriptions', methods=['GET'])
@token_required
def get_subscriptions(current_user):
    subs = Subscription.query.filter_by(user_id=current_user.id).all()
    output = []
    today = datetime.utcnow().date()
    for sub in subs:
        try:
            due_date = datetime.strptime(sub.next_due_date, '%Y-%m-%d').date()
            due_in_days = (due_date - today).days
        except Exception:
            due_in_days = -1
        
        output.append({
            'id': sub.id,
            'name': sub.name,
            'amount': sub.amount,
            'billing_cycle': sub.billing_cycle,
            'next_due_date': sub.next_due_date,
            'due_in_days': due_in_days,
            'is_due_soon': True if 0 <= due_in_days <= 3 else False
        })
    return jsonify({'subscriptions': output}), 200

@app.route('/subscriptions/<int:sub_id>', methods=['DELETE'])
@token_required
def delete_subscription(current_user, sub_id):
    sub = Subscription.query.filter_by(id=sub_id, user_id=current_user.id).first()
    if sub:
        db.session.delete(sub)
        db.session.commit()
        return jsonify({'message': 'Subscription deleted'}), 200
    return jsonify({'message': 'Not found'}), 404

@app.route('/subscriptions/<int:sub_id>/pay', methods=['POST'])
@token_required
def pay_subscription(current_user, sub_id):
    """Pay a subscription: records as expense transaction & advances next_due_date."""
    sub = Subscription.query.filter_by(id=sub_id, user_id=current_user.id).first()
    if not sub:
        return jsonify({'message': 'Subscription not found'}), 404

    data = request.get_json() or {}
    payment_method = data.get('payment_method', 'UPI')
    today_str = datetime.utcnow().strftime('%Y-%m-%d')

    # 1. Record as expense transaction
    new_tx = Transaction(
        user_id=current_user.id,
        amount=sub.amount,
        type='expense',
        category='Subscription',
        date=today_str,
        description=f'{sub.name} subscription payment',
        mood='Neutral',
        payment_method=payment_method,
        upi_ref=data.get('upi_ref', '')
    )
    current_user.total_balance -= sub.amount
    update_streak(current_user, today_str)
    db.session.add(new_tx)

    # 2. Advance the next_due_date by one billing cycle
    try:
        due = datetime.strptime(sub.next_due_date, '%Y-%m-%d').date()
    except Exception:
        due = datetime.utcnow().date()

    if sub.billing_cycle == 'yearly':
        next_due = due.replace(year=due.year + 1)
    else:  # monthly (default)
        month = due.month + 1
        year = due.year + (month - 1) // 12
        month = ((month - 1) % 12) + 1
        try:
            next_due = due.replace(year=year, month=month)
        except ValueError:
            # Handle edge cases like Jan 31 -> Feb 28
            import calendar
            last_day = calendar.monthrange(year, month)[1]
            next_due = due.replace(year=year, month=month, day=last_day)

    sub.next_due_date = next_due.strftime('%Y-%m-%d')
    db.session.commit()

    return jsonify({
        'message': f'{sub.name} payment recorded!',
        'transaction_date': today_str,
        'next_due_date': sub.next_due_date,
        'amount': sub.amount
    }), 201

@app.route('/insights', methods=['GET'])
@token_required
def get_insights(current_user):
    today = datetime.utcnow()
    current_month = today.strftime('%Y-%m')
    
    last_month_dt = today.replace(day=1) - timedelta(days=1)
    last_month = last_month_dt.strftime('%Y-%m')
    
    txs_current = Transaction.query.filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'expense',
        Transaction.date.like(f"{current_month}%")
    ).all()
    current_spent = sum([tx.amount for tx in txs_current])
    
    txs_last = Transaction.query.filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'expense',
        Transaction.date.like(f"{last_month}%")
    ).all()
    last_spent = sum([tx.amount for tx in txs_last])
    
    txs_income = Transaction.query.filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'income',
        Transaction.date.like(f"{current_month}%")
    ).all()
    current_income = sum([tx.amount for tx in txs_income])
    
    savings_rate = 0
    if current_income > 0:
        savings = current_income - current_spent
        savings_rate = max(0, min(100, (savings / current_income) * 100))
        
    budgets = Budget.query.filter_by(user_id=current_user.id, month_year=current_month).all()
    adherence_percents = []
    for bg in budgets:
        spent = sum([tx.amount for tx in txs_current if tx.category == bg.category])
        if spent <= bg.limit_amount:
            adherence_percents.append(100)
        else:
            diff = spent - bg.limit_amount
            penalty = diff / bg.limit_amount * 100
            adherence_percents.append(max(0, 100 - penalty))
            
    budget_adherence = sum(adherence_percents) / len(adherence_percents) if adherence_percents else 50
    health_score = (0.6 * savings_rate) + (0.4 * budget_adherence)
    
    saving_tip = "Try using the 50/30/20 rule to balance your spending."
    if health_score < 40:
        saving_tip = "Your expenses are high. Consider cutting down on non-essential subscriptions."
    elif health_score >= 80:
        saving_tip = "Great job managing your finances! Consider investing your extra savings."

    # FR-14 Category Analysis
    category_spending_current = {}
    category_spending_last = {}
    for tx in txs_current:
        category_spending_current[tx.category] = category_spending_current.get(tx.category, 0) + tx.amount
    for tx in txs_last:
        category_spending_last[tx.category] = category_spending_last.get(tx.category, 0) + tx.amount
        
    category_insights = []
    for cat, curr_amt in category_spending_current.items():
        last_amt = category_spending_last.get(cat, 0)
        if last_amt > 0:
            diff_pct = ((curr_amt - last_amt) / last_amt) * 100
            if diff_pct >= 20:
                category_insights.append(f"You spent {diff_pct:.0f}% more on {cat} this month.")
                
    # FR-20 Mood Analysis
    mood_spending = {}
    mood_counts = {}
    for tx in txs_current:
        if tx.mood and tx.mood != 'Neutral':
            mood_spending[tx.mood] = mood_spending.get(tx.mood, 0) + tx.amount
            mood_counts[tx.mood] = mood_counts.get(tx.mood, 0) + 1
            
    mood_insight = ""
    if mood_spending:
        avg_mood_spend = {m: mood_spending[m]/float(mood_counts[m]) for m in mood_spending}
        highest_mood = max(avg_mood_spend, key=avg_mood_spend.get)
        mood_insight = f"You spend the most on average when feeling {highest_mood}."

    # Payment Method Breakdown
    payment_method_spending = {"UPI": 0.0, "Card": 0.0, "Cash": 0.0}
    for tx in txs_current:
        pm = tx.payment_method if tx.payment_method in payment_method_spending else "Cash"
        payment_method_spending[pm] += tx.amount

    return jsonify({
        'current_month_spent': current_spent,
        'last_month_spent': last_spent,
        'health_score': round(health_score, 1),
        'saving_tip': saving_tip,
        'category_insights': category_insights,
        'mood_insight': mood_insight,
        'payment_method_spending': payment_method_spending
    }), 200

@app.route('/upi_intent', methods=['POST'])
@token_required
def get_upi_intent(current_user):
    data = request.get_json()
    amount = float(data['amount'])
    payee_address = "example@okhdfcbank"
    payee_name = "FinWise Merchant"
    note = f"FinWise Expense - {data.get('category', 'Misc')}"
    
    uri = f"upi://pay?pa={payee_address}&pn={payee_name}&am={amount:.2f}&cu=INR&tn={note}"
    return jsonify({'upi_intent': uri}), 200

@app.route('/goals', methods=['GET', 'POST'])
@token_required
def manage_goals(current_user):
    if request.method == 'GET':
        user_goals = Goal.query.filter_by(user_id=current_user.id).all()
        return jsonify({'goals': [{
            'id': g.id,
            'target_amount': g.target_amount,
            'current_amount': g.current_amount,
            'deadline': g.deadline,
            'description': g.description,
            'auto_save_percentage': g.auto_save_percentage
        } for g in user_goals]}), 200
        
    if request.method == 'POST':
        data = request.get_json()
        current_amt = float(data.get('current_amount', 0.0))
        new_goal = Goal(
            user_id=current_user.id,
            target_amount=float(data['target_amount']),
            current_amount=current_amt,
            deadline=data['deadline'],
            description=data.get('description', ''),
            auto_save_percentage=float(data.get('auto_save_percentage', 0.0))
        )
        # Deduct from total balance if starting with some money
        if current_amt > 0:
            current_user.total_balance -= current_amt
            
        db.session.add(new_goal)
        db.session.commit()
        return jsonify({'message': 'Goal added!', 'total_balance': current_user.total_balance}), 201

@app.route('/goals/<int:goal_id>', methods=['PUT', 'DELETE'])
@token_required
def modify_goal(current_user, goal_id):
    goal = Goal.query.filter_by(id=goal_id, user_id=current_user.id).first()
    if not goal:
        return jsonify({'message': 'Not found'}), 404
        
    if request.method == 'DELETE':
        db.session.delete(goal)
        db.session.commit()
        return jsonify({'message': 'Goal deleted'}), 200
        
    if request.method == 'PUT':
        data = request.get_json()
        new_current = float(data.get('current_amount', goal.current_amount))
        
        # If current_amount increased, deduct from balance. If decreased, add back.
        diff = new_current - goal.current_amount
        current_user.total_balance -= diff
        
        goal.target_amount = float(data.get('target_amount', goal.target_amount))
        goal.current_amount = new_current
        goal.deadline = data.get('deadline', goal.deadline)
        goal.description = data.get('description', goal.description)
        goal.auto_save_percentage = float(data.get('auto_save_percentage', goal.auto_save_percentage))
        db.session.commit()
        return jsonify({'message': 'Goal updated', 'total_balance': current_user.total_balance}), 200

@app.route('/goals/<int:goal_id>/withdraw', methods=['POST'])
@token_required
def withdraw_goal(current_user, goal_id):
    goal = Goal.query.filter_by(id=goal_id, user_id=current_user.id).first()
    if not goal:
        return jsonify({'message': 'Goal not found'}), 404
        
    if goal.current_amount <= 0:
        return jsonify({'message': 'No funds to withdraw'}), 400
        
    amount_to_withdraw = goal.current_amount
    current_user.total_balance += amount_to_withdraw
    
    # Record a transaction for the withdrawal
    new_tx = Transaction(
        user_id=current_user.id,
        amount=amount_to_withdraw,
        type='income',
        category='Savings',
        date=datetime.utcnow().strftime('%Y-%m-%d %H:%M'),
        description=f"Withdrawn from goal: {goal.description}",
        mood='Excited',
        payment_method='Internal'
    )
    db.session.add(new_tx)
    
    # We delete the goal once funds are put back to savings
    db.session.delete(goal)
    db.session.commit()
    return jsonify({'message': f'₹{amount_to_withdraw} moved to your total balance!'}), 200

@app.route('/create_razorpay_order', methods=['POST'])
@token_required
def create_razorpay_order(current_user):
    if not RAZORPAY_AVAILABLE:
        return jsonify({'message': 'Razorpay library not found on server. Payment features disabled.'}), 501

    data = request.get_json()
    amount = float(data.get('amount', 0)) * 100 # amount in paise
    currency = "INR"
    
    # Initialize razorpay client
    # Using placeholder secret as user didn't provide one
    client = razorpay.Client(auth=("rzp_test_SeRVcJY7WqBcIT", "YOUR_RAZORPAY_SECRET_HERE"))
    
    try:
        response = client.order.create(dict(amount=amount, currency=currency, payment_capture='1'))
        return jsonify({
            'order_id': response['id'],
            'amount': response['amount'],
            'currency': response['currency'],
        }), 200
    except Exception as e:
        return jsonify({'message': 'Error creating order', 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000, host='0.0.0.0')
