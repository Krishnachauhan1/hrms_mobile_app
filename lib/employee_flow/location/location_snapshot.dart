class LocationSnapshot {
  final bool trackingEnabled;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSentAt;
  final DateTime? lastAttemptAt;
  final String? lastError;

  const LocationSnapshot({
    required this.trackingEnabled,
    this.latitude,
    this.longitude,
    this.lastSentAt,
    this.lastAttemptAt,
    this.lastError,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get coordinatesText => hasCoordinates
      ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
      : '—';

  Duration? get timeUntilNextRefresh {
    if (lastSentAt == null) return null;
    const interval = Duration(minutes: 10);
    final next = lastSentAt!.add(interval);
    final remaining = next.difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  String get nextRefreshText {
    final remaining = timeUntilNextRefresh;
    if (!trackingEnabled) return '—';
    if (remaining == null) return 'After check-in';
    if (remaining == Duration.zero) return 'Updating soon';
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
