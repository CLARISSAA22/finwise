import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  static Future<void> showGoalCompletedNotification(Goal goal) async {
    await _notificationsPlugin.show(
      goal.id + 1000, // Unique ID offset
      'Goal Completed! 🎉',
      'Congratulations! You\'ve reached your target of ₹${goal.targetAmount.toStringAsFixed(0)} for ${goal.description}!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_channel',
          'Goal Achievements',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  static Future<void> scheduleDueReminder(Subscription sub) async {
    final DateTime dueDate = DateTime.parse(sub.nextDueDate);
    // Schedule for 9 AM one day before due date
    final scheduleDate = dueDate.subtract(const Duration(days: 1)).add(const Duration(hours: 9));

    if (scheduleDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      sub.id,
      'Subscription Due Reminder',
      'Your ${sub.name} subscription (₹${sub.amount}) is due tomorrow!',
      tz.TZDateTime.from(scheduleDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'subscription_channel',
          'Subscription Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
