import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> scheduleEmiReminder({
    required int id,
    required String loanName,
    required double amount,
    required DateTime dueDate,
  }) async {
    final reminderDate = dueDate.subtract(const Duration(days: 5));
    if (reminderDate.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      'EMI Due Soon',
      '$loanName ₹${amount.toStringAsFixed(0)} due in 5 days',
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('emi', 'EMI Reminders',
            channelDescription: 'Loan EMI due reminders', importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleCreditCardReminder({
    required int id,
    required String cardName,
    required double minDue,
    required DateTime dueDate,
  }) async {
    final reminderDate = dueDate.subtract(const Duration(days: 3));
    if (reminderDate.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id + 1000,
      'Credit Card Due',
      '$cardName min due ₹${minDue.toStringAsFixed(0)} in 3 days',
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('cc', 'Credit Card Reminders',
            channelDescription: 'Credit card due reminders', importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleInsuranceReminder({
    required int id,
    required String policyName,
    required double premium,
    required DateTime dueDate,
  }) async {
    final reminderDate = dueDate.subtract(const Duration(days: 7));
    if (reminderDate.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id + 2000,
      'Insurance Renewal',
      '$policyName due in 7 days — ₹${premium.toStringAsFixed(0)}',
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('insurance', 'Insurance Reminders',
            channelDescription: 'Insurance renewal reminders', importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleMonthlyAdvanceTaxReminders() async {
    final now = DateTime.now();
    final deadlines = [
      DateTime(now.year, 6, 15),
      DateTime(now.year, 9, 15),
      DateTime(now.year, 12, 15),
      DateTime(now.year + 1, 3, 15),
    ];
    for (var i = 0; i < deadlines.length; i++) {
      final reminder = deadlines[i].subtract(const Duration(days: 5));
      if (reminder.isAfter(now)) {
        await _plugin.zonedSchedule(
          9000 + i,
          'Advance Tax Due in 5 Days',
          'Deadline: ${deadlines[i].day}/${deadlines[i].month}/${deadlines[i].year}',
          tz.TZDateTime.from(DateTime(reminder.year, reminder.month, reminder.day, 9), tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails('tax', 'Tax Reminders',
                channelDescription: 'Advance tax reminders', importance: Importance.high),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
