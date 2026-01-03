class BulkPjpResult {
  final bool success;
  final String message;
  final int totalVisitsCreated;

  const BulkPjpResult({
    required this.success,
    required this.message,
    this.totalVisitsCreated = 0,
  });
}