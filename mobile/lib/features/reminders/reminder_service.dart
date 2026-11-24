import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/formatters.dart';
import '../habits/data/habit.dart';
import 'reminder_planner.dart';

/// Schedules habit reminders as local notifications on Android and iOS.
class ReminderService {
  ReminderService._();

  static final instance = ReminderService._();

  static const _channelId = 'habit_reminders';
  static const _payloadOpenHabits = 'open_habits';

  /// iOS keeps at most 64 pending notifications per app.
  static const _maxPendingIos = 60;
  static const _maxPendingAndroid = 150;
  static const _daysAhead = 2;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Called when the user taps a reminder.
  VoidCallback? onOpenHabits;

  static bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (!isSupported || _initialized) return;

    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Unknown zone name: tz.local stays UTC and times are converted from the device clock below.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == _payloadOpenHabits) onOpenHabits?.call();
      },
    );
    _initialized = true;
  }

  /// True when the app opened because the user tapped a reminder.
  Future<bool> launchedFromReminder() async {
    if (!isSupported) return false;
    await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    return (details?.didNotificationLaunchApp ?? false) &&
        details?.notificationResponse?.payload == _payloadOpenHabits;
  }

  /// Asks for permission to post notifications. With [exactAlarms], Android also opens the
  /// "Alarms & reminders" setting so reminders fire on the minute instead of being batched.
  Future<bool> requestPermission({bool exactAlarms = false}) async {
    if (!isSupported) return false;
    await init();
    if (_isAndroid) {
      final granted = await _android?.requestNotificationsPermission() ?? false;
      if (granted && exactAlarms && !(await _android?.canScheduleExactNotifications() ?? false)) {
        await _android?.requestExactAlarmsPermission();
      }
      return granted;
    }
    return await _ios?.requestPermissions(alert: true, sound: true, badge: true) ?? false;
  }

  /// Replaces every pending reminder with a fresh plan for today and the next day.
  Future<int> reschedule({
    required List<Habit> habits,
    required Set<int> completedToday,
    int leadMinutes = 15,
    int intervalMinutes = 15,
  }) async {
    if (!isSupported) return 0;
    await init();
    await _plugin.cancelAllPendingNotifications();

    final planner = ReminderPlanner(
      leadTime: Duration(minutes: leadMinutes),
      interval: Duration(minutes: intervalMinutes),
    );
    final reminders = planner.plan(
      habits: habits,
      completedToday: completedToday,
      now: DateTime.now(),
      days: _daysAhead,
      maxCount: _isAndroid ? _maxPendingAndroid : _maxPendingIos,
    );
    final mode = _isAndroid && (await _android?.canScheduleExactNotifications() ?? false)
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (var i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      await _plugin.zonedSchedule(
        id: i,
        title: _title(r),
        body: _body(r),
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Habit reminders',
            channelDescription: 'Reminders before and during each habit until it is marked done',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBanner: true, presentList: true),
        ),
        androidScheduleMode: mode,
        payload: _payloadOpenHabits,
      );
    }
    return reminders.length;
  }

  /// Whether the OS currently lets this app post notifications; null where unsupported.
  Future<bool?> notificationsAllowed() async {
    if (!isSupported) return null;
    await init();
    if (_isAndroid) return _android?.areNotificationsEnabled();
    return (await _ios?.checkPermissions())?.isEnabled;
  }

  Future<void> openSystemSettings() async {
    if (!isSupported) return;
    await init();
    if (_isAndroid) {
      await _android?.openAppNotificationSettings();
    } else {
      await _ios?.openAppNotificationSettings();
    }
  }

  Future<void> clear() async {
    if (!isSupported) return;
    await init();
    await _plugin.cancelAll();
  }

  String _title(PlannedReminder r) => r.isBeforeStart ? 'Coming up: ${r.habit.name}' : r.habit.name;

  String _body(PlannedReminder r) {
    final time = Fmt.time(r.habit.startTime);
    if (r.isBeforeStart) {
      final minutes = r.start.difference(r.at).inMinutes;
      return 'Starts at $time, in $minutes minutes.';
    }
    if (r.at == r.start) return "It's time! Tap to mark it done.";
    return 'Not done yet (started at $time). Tap to mark it done.';
  }
}
