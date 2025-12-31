enum PjpCreateMode {
  single,
  bulk,
}

class PjpCreateResult {
  final PjpCreateMode mode;

  const PjpCreateResult({required this.mode});
}
