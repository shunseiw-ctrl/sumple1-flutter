class PaymentTestStep {
  final String name;
  final bool success;
  final String detail;

  const PaymentTestStep(this.name, this.success, this.detail);

  @override
  String toString() => '$name: ${success ? "OK" : "FAIL"} - $detail';
}

class PaymentTestResult {
  final List<PaymentTestStep> steps;
  final DateTime testedAt;

  PaymentTestResult({
    required this.steps,
    DateTime? testedAt,
  }) : testedAt = testedAt ?? DateTime.now();

  bool get allPassed => steps.every((s) => s.success);
  int get passedCount => steps.where((s) => s.success).length;
  int get failedCount => steps.where((s) => !s.success).length;

  PaymentTestResult addStep(PaymentTestStep step) {
    return PaymentTestResult(
      steps: [...steps, step],
      testedAt: testedAt,
    );
  }
}
