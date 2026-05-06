from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    total_balance = db.Column(db.Float, default=0.0)
    streak = db.Column(db.Integer, default=1)
    last_entry_date = db.Column(db.String(10), nullable=True) # YYYY-MM-DD
    badges = db.Column(db.String(255), default="") # Comma-separated badges
    upi_id = db.Column(db.String(100), nullable=True)

class Transaction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    type = db.Column(db.String(10), nullable=False) # 'income' or 'expense'
    category = db.Column(db.String(50), nullable=False)
    date = db.Column(db.String(20), nullable=False) # YYYY-MM-DD HH:MM
    description = db.Column(db.String(255))
    mood = db.Column(db.String(50)) # Happy/Sad/Stressed/Excited/Neutral
    payment_method = db.Column(db.String(50)) # Cash/Card/UPI
    upi_ref = db.Column(db.String(100))
    user = db.relationship('User', backref=db.backref('transactions', lazy=True))

class Budget(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    category = db.Column(db.String(50), nullable=False)
    limit_amount = db.Column(db.Float, nullable=False)
    month_year = db.Column(db.String(7), nullable=False) # Format: YYYY-MM
    user = db.relationship('User', backref=db.backref('budgets', lazy=True))

class Subscription(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    billing_cycle = db.Column(db.String(20), nullable=False) # monthly/yearly
    next_due_date = db.Column(db.String(10), nullable=False) # YYYY-MM-DD
    user = db.relationship('User', backref=db.backref('subscriptions', lazy=True))

class Goal(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    target_amount = db.Column(db.Float, nullable=False)
    current_amount = db.Column(db.Float, default=0.0)
    deadline = db.Column(db.String(10), nullable=False) # YYYY-MM-DD
    description = db.Column(db.String(255))
    auto_save_percentage = db.Column(db.Float, default=0.0)
    user = db.relationship('User', backref=db.backref('goals', lazy=True))
