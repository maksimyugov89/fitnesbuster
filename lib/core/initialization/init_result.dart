class InitResult {
  final bool success;
  final String stageName;
  final String? error;

  const InitResult({
    required this.success,
    required this.stageName,
    this.error,
  });

  factory InitResult.ok(String stage) =>
      InitResult(success: true, stageName: stage);
  factory InitResult.fail(String stage, String error) =>
      InitResult(success: false, stageName: stage, error: error);
}
