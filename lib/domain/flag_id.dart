/// Open namespace: new catalogs can define categories without changing the core.
final class FlagCategory {
  factory FlagCategory(String value) {
    if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(value)) {
      throw ArgumentError.value(value, 'value', 'Invalid flag category');
    }
    return FlagCategory._(value);
  }
  const FlagCategory._(this.value);
  static const country = FlagCategory._('country');
  final String value;
  @override
  bool operator ==(Object other) =>
      other is FlagCategory && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

/// Case-sensitive, locale-independent identity. Parsing never guesses a category.
final class FlagId {
  factory FlagId(FlagCategory category, String value) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$').hasMatch(value)) {
      throw ArgumentError.value(value, 'value', 'Invalid flag identifier');
    }
    return FlagId._(category, value);
  }
  const FlagId._(this.category, this.value);
  final FlagCategory category;
  final String value;

  static FlagId? tryParse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    try {
      return FlagId(FlagCategory(parts[0]), parts[1]);
    } on ArgumentError {
      return null;
    }
  }

  @override
  String toString() => '${category.value}:$value';
  @override
  bool operator ==(Object other) =>
      other is FlagId && category == other.category && value == other.value;
  @override
  int get hashCode => Object.hash(category, value);
}
