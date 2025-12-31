typedef FeatureFactory<T> = T Function();

class AppKernel {
  AppKernel._();
  static final AppKernel instance = AppKernel._();

  final Map<Type, Object> _features = <Type, Object>{};

  /// Register a feature if enabled
void registerIf<T extends Object>(
  bool condition,
  FeatureFactory<T> factory,
) {
  if (condition) {
    _features[T] = factory();
  }
}

  /// Access a registered feature
  T feature<T>() {
    final feature = _features[T];
    if (feature == null) {
      throw Exception(
        'Feature $T is not registered in AppKernel',
      );
    }
    return feature as T;
  }

  /// Optional: cleanup (future-proof)
  void clear() {
    _features.clear();
  }
}
