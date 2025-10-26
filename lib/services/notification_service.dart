// Notification service stub
//
// The full implementation (using flutter_local_notifications + timezone)
// was removed to avoid build errors while those native packages are
// temporarily disabled. This stub preserves the public API so the
// rest of the app can call these methods without change. Re-enable
// the real implementation when the native packages are available.

class NotificationService {
  /// No-op initializer. Real implementation will configure
  /// platform-specific notification channels and timezone data.
  static Future<void> init() async {
    return;
  }

  /// No-op scheduler. Parameters are kept to match the original API.
  static Future<void> scheduleExpiryNotification(int id, String title, String body, DateTime scheduledDate) async {
    // Intentionally do nothing in the stub.
    return;
  }
}
