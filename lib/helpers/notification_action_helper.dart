
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import 'database_helper.dart';
import 'notification_helper.dart';

class NotificationActionHelper {
  /// 🔥 복용 완료 처리 (기록 + 다음 알림 예약)
  static Future<void> handleTaken(
    BuildContext context,
    Reminder reminder,
  ) async {
    try {
      // 1. 복용 기록 저장
      await NotificationHelper.markAsTaken(reminder.id!);

      // 2. 다음 알림 예약
      await NotificationHelper.scheduleNextNotification(reminder.id!);

      // 3. 화면 닫기 & 메시지
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('복용 완료! 다음 스케줄에 알려드릴게요'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 복용 완료 처리 실패: $e');
    }
  }

  /// 🔥 10분 후 알림
  static Future<void> handleSnooze(
    BuildContext context,
    int reminderId,
  ) async {
    try {
      await NotificationHelper.snoozeNotification(reminderId, 10);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('10분 후 다시 알려드릴게요'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 10분 후 알림 실패: $e');
    }
  }

  /// 🔥 내일 다시 알림 (건너뛰기)
  static Future<void> handleSkipToNextDay(
    BuildContext context,
    int reminderId,
  ) async {
    try {
      // 건너뛰기 기록 + 다음 알림 예약
      await NotificationHelper.markAsSkipped(reminderId);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('내일 같은 시간에 알려드릴게요'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 내일 알림 실패: $e');
    }
  }

  /// 🔥 닫기 (나중에 확인)
  static void handleClose(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('2시간 후 다시 확인할게요'),
        backgroundColor: Colors.grey[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
