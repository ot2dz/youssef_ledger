// lib/data/local/db_bus.dart
import 'dart:async';

/// Simple event bus for database change notifications
///
/// This utility allows UI components to listen for database changes
/// and refresh their data accordingly, ensuring consistency across the app.
class DbBus {
  static final DbBus instance = DbBus._();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  DbBus._();

  /// Stream of database change events
  Stream<void> get stream => _controller.stream;

  /// Notify all listeners that the database has changed
  ///
  /// Call this after any insert, update, or delete operation
  /// to trigger UI refreshes.
  void bump() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  /// Close the stream controller (call during app shutdown)
  void dispose() {
    _controller.close();
  }
}
