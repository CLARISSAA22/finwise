class User {
  final int id;// id of the user 
  final String name;//name of the user
  final String email;//email of the user
  final double totalBalance;//total balance of the user
  final int streak;//streak of the user
  final List<String> badges;//list of badges of the user
  final String? upiId;
//constructor 
  User({
    required this.id, //assigning argument for user id
    required this.name, //assigning argument for user name
    required this.email,//assigning argument for user email
    required this.totalBalance,//assigning argument for user total balance
    required this.streak, //assigning argument for user streak
    required this.badges, //assigning argument for user badges
    this.upiId //assigning argument for user upi id
    });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,//storing the user id if its null then 0
      name: json['name'] ?? '',//storing the user name if its null then ''
      email: json['email'] ?? '',//storing the user email if its null then ''
      totalBalance: (json['total_balance'] ?? 0).toDouble(),//storing the user total balance if its null then 0.0
      streak: json['streak'] ?? 0,//storing the user streak if its null then 0
      badges: json['badges'] != null ? List<String>.from(json['badges']) : [],//storing the user badges if its null then []
      upiId: json['upi_id']//storing the user upi id
    );
  }
}
//transactions details 
class Transaction {
  //declaration of variables for transactions 
  final int id; //transaction id 
  final double amount; //amount 
  final String type; //income or expense
  final String category; //category of transaction 
  final String date; //date of transaction 
  final String description; //description of transaction 
  final String mood; //mood of user 
  final String paymentMethod; //payment mood used

  Transaction(
    {required this.id,//assigning argument for transaction id
     required this.amount, //assigning argument for transaction amount
     required this.type, //assigning argument for transaction type
     required this.category, //assigning argument for transaction category
     required this.date, //assigning argument for transaction date
     required this.description, //assigning argument for transaction description
     required this.mood, //assigning argument for transaction mood
     required this.paymentMethod //assigning argument for transaction payment method
     }
     );

  factory Transaction.fromJson(Map<String, dynamic> json)
   {
    return Transaction(
      id: json['id'] ?? 0,//storing the transaction id if its null then 0
      amount: (json['amount'] ?? 0).toDouble(),//storing the transaction amount if its null then 0.0
      type: json['type'] ?? '',//storing the transaction type if its null then ''
      category: json['category'] ?? '',//storing the transaction category if its null then ''
      date: json['date'] ?? '',//storing the transaction date if its null then ''
      description: json['description'] ?? '',//storing the transaction description if its null then ''
      mood: json['mood'] ?? 'Neutral',//storing the transaction mood if its null then 'Neutral'
      paymentMethod: json['payment_method'] ?? 'Cash',//storing the transaction payment method if its null then 'Cash'
    );
  }
}

class Budget {
  final int id;//budget id
  final String category;//assigning argument for budget category
  final double limitAmount;//assigning argument for budget limit amount
  final String monthYear;//assigning argument for budget month and year
  final double spent;//assigning argument for budget spent amount

  Budget(
    {
      required this.id, //assigning argument for budget id
      required this.category, //assigning argument for budget category
      required this.limitAmount, //assigning argument for budget limit amount
      required this.monthYear, //assigning argument for budget month and year
      required this.spent //assigning argument for budget spent amount
    }
  );
  
  factory Budget.fromJson(Map<String, dynamic> json) 
  {
    return Budget(
      id: json['id'] ?? 0,//storing the budget id if its null then 0
      category: json['category'] ?? '',//storing the budget category if its null then 
      limitAmount: (json['limit_amount'] ?? 0).toDouble(),//storing the budget limit amount if its null then 0.0
      monthYear: json['month_year'] ?? '',//storing the budget month and year if its null then ''
      spent: (json['spent'] ?? 0).toDouble(),//storing the budget spent amount if its null then 0.0
    );
  }
}
//subscription model
class Subscription 
{
  final int id; //subscription id
  final String name; //subscription name
  final double amount; //subscription amount
  final String billingCycle; //subscription billing cycle
  final String nextDueDate; //subscription next due date
  final int dueInDays; //subscription due in days
  final bool isDueSoon; //subscription due soon

  Subscription(
    {
      required this.id, //assigning argument for subscription id
      required this.name, //assigning argument for subscription name
      required this.amount, //assigning argument for subscription amount
      required this.billingCycle, //assigning argument for subscription billing cycle
      required this.nextDueDate, //assigning argument for subscription next due date
      required this.dueInDays, //assigning argument for subscription due in days
      required this.isDueSoon //assigning argument for subscription due soon
    }
  );

  factory Subscription.fromJson(Map<String, dynamic> json) 
  {
    return Subscription(
      id: json['id'] ?? 0,//storing the subscription id if its null then 0
      name: json['name'] ?? '',//storing the subscription name if its null then ''
      amount: (json['amount'] ?? 0).toDouble(),//storing the subscription amount if its null then 0.0
      billingCycle: json['billing_cycle'] ?? '',//storing the subscription billing cycle if its null then ''
      nextDueDate: json['next_due_date'] ?? '',//storing the subscription next due date if its null then ''
      dueInDays: json['due_in_days'] ?? -1,//storing the subscription due in days if its null then -1
      isDueSoon: json['is_due_soon'] ?? false,//storing the subscription due soon if its null then false
    );
  }
}
//goal model
class Goal {
  final int id; //goal id
  final double targetAmount; //goal target amount
  final double currentAmount; //goal current amount
  final String deadline; //goal deadline
  final String description; //goal description
  final double autoSavePercentage; //goal auto save percentage

  Goal(
    {
      required this.id, //assigning argument for goal id
      required this.targetAmount, //assigning argument for goal target amount
      required this.currentAmount, //assigning argument for goal current amount
      required this.deadline, //assigning argument for goal deadline
      required this.description, //assigning argument for goal description
      this.autoSavePercentage = 0.0 //assigning argument for goal auto save percentage
    }); 

  factory Goal.fromJson(Map<String, dynamic> json) 
  {
    return Goal(
      id: json['id'] ?? 0,// get goal id from backend if its null then 0
      targetAmount: (json['target_amount'] ?? 0).toDouble(),// get goal target amount from backend if its null then 0.0
      currentAmount: (json['current_amount'] ?? 0).toDouble(),// get goal current amount from backend if its null then 0.0
      deadline: json['deadline'] ?? '',// get goal deadline from backend if its null then ''
      description: json['description'] ?? '',// get goal description from backend if its null then ''
      autoSavePercentage: (json['auto_save_percentage'] ?? 0).toDouble(),// get goal auto save percentage from backend if its null then 0.0
    );
  }
}