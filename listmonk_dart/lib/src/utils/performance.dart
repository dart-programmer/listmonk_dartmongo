import 'dart:async';
import 'logger.dart';

/// Performance monitoring utility
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  /// Start a performance timer
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
    Logger.debug('Started timer for: $operation');
  }

  /// Stop a performance timer and log the result
  static Duration stopTimer(String operation) {
    final timer = _timers.remove(operation);
    if (timer == null) {
      Logger.warning('Timer not found for operation: $operation');
      return Duration.zero;
    }

    timer.stop();
    final duration = timer.elapsed;
    Logger.performance(operation, duration);
    return duration;
  }

  /// Measure the execution time of an async operation
  static Future<T> measureAsync<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    startTimer(operation);
    try {
      final result = await function();
      stopTimer(operation);
      return result;
    } catch (e) {
      stopTimer(operation);
      rethrow;
    }
  }

  /// Measure the execution time of a sync operation
  static T measureSync<T>(
    String operation,
    T Function() function,
  ) {
    startTimer(operation);
    try {
      final result = function();
      stopTimer(operation);
      return result;
    } catch (e) {
      stopTimer(operation);
      rethrow;
    }
  }

  /// Get all active timers
  static Map<String, Duration> getActiveTimers() {
    final activeTimers = <String, Duration>{};
    _timers.forEach((operation, timer) {
      activeTimers[operation] = timer.elapsed;
    });
    return activeTimers;
  }

  /// Clear all timers
  static void clearAllTimers() {
    _timers.clear();
    Logger.debug('Cleared all performance timers');
  }
}