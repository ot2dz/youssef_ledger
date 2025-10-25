// lib/data/local/db_bus.dart
import 'dart:async';

/// Optimized event bus for database change notifications with debouncing
///
/// This utility allows UI components to listen for database changes
/// and refresh their data accordingly, ensuring consistency across the app.
///
/// Uses a 300ms debounce to prevent excessive rebuilds when multiple
/// database operations occur in quick succession.
class DbBus {
  static final DbBus instance = DbBus._();

  final StreamController<void> _controller = StreamController<void>.broadcast();
  Timer? _debounceTimer;

  // Debounce duration - waits 300ms after last bump() call before notifying
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  DbBus._();

  /// Stream of database change events
  Stream<void> get stream => _controller.stream;

  /// Notify all listeners that the database has changed (with debouncing)
  ///
  /// Call this after any insert, update, or delete operation.
  /// Multiple rapid calls will be batched - only the last one triggers
  /// a notification after 300ms of inactivity.
  ///
  /// This significantly reduces unnecessary UI rebuilds during bulk operations.
  void bump() {
    if (_controller.isClosed) return;

    // Cancel existing timer if any
    _debounceTimer?.cancel();

    // Start new timer
    _debounceTimer = Timer(_debounceDuration, () {
      if (!_controller.isClosed) {
        _controller.add(null);
      }
    });
  }

  /// Immediately notify listeners without debouncing
  ///
  /// Use this sparingly - only when you need instant UI updates
  /// (e.g., critical user feedback scenarios)
  void bumpImmediate() {
    _debounceTimer?.cancel();
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  /// Close the stream controller (call during app shutdown)
  void dispose() {
    _debounceTimer?.cancel();
    _controller.close();
  }
}
