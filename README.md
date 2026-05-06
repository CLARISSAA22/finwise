# FinWise - AI-Powered Financial Manager

FinWise is a comprehensive full-stack financial management application built as a BCA Final Year Project. It empowers users to track their spending, manage budgets, monitor subscriptions, and set savings goals—all while receiving AI-driven insights into their financial health.

## 🚀 Key Features

- **Intuitive Dashboard**: Real-time balance tracking, recent transactions, and quick-action shortcuts.
- **Smart Budgeting**: Set monthly spending limits per category with automatic 80% and 100% threshold alerts.
- **Wealth Tracking**: Centralized management for Savings Goals and Subscriptions with renewal reminders.
- **AI Insights**: Automated financial health scoring and personalized saving tips based on spending patterns and user mood.
- **Gamification**: Earn badges and maintain streaks by consistently tracking finances.
- **UPI Integration**: Generate UPI payment intents and simulate secure payments via Razorpay.

## 🛠️ Technology Stack

- **Frontend**: Flutter (Dart) with Provider for state management and `fl_chart` for data visualization.
- **Backend**: Flask (Python) with SQLAlchemy (SQLite) for a robust RESTful API.
- **Security**: JWT-based authentication with bcrypt password hashing.

## 📂 Project Structure

```text
finWise_sample/
├── backend/
│   ├── app.py             # Main Flask API & Logic
│   ├── models.py          # SQLAlchemy Database Schema
│   └── test_api.py        # Automated API Verification Suite
└── frontend/
    ├── lib/
    │   ├── models/        # Data Models
    │   ├── providers/     # State Management (Auth & Finance)
    │   ├── screens/       # UI Screens (10+ interactive screens)
    │   └── utils/         # Constants & Styling
    └── pubspec.yaml       # Project Dependencies
```

## ⚙️ How to Run

### 1. Backend Setup
1. Navigate to the `backend` folder.
2. Install dependencies: `pip install flask flask-sqlalchemy flask-cors flask-bcrypt PyJWT razorpay`.
3. Run the server: `python app.py`.
   - *The server will host on `http://0.0.0.0:5000` to be accessible by your emulator.*

### 2. Frontend Setup
1. Navigate to the `frontend` folder.
2. Fetch dependencies: `flutter pub get`.
3. Launch an Android Emulator (Pixel 4 or higher recommended).
4. Run the app: `flutter run`.

## 🧪 Verification
You can run the automated test suite to verify all 10+ API routes and data integrity:
```bash
cd backend
python test_api.py
```
