import 'flag.dart';

class Country {
  Country({required this.code, required this.name, required List<Flag> flags})
    : flags = List.unmodifiable(flags) {
    if (this.flags.where((flag) => flag.endYear == null).length != 1) {
      throw ArgumentError('A country must have exactly one current flag.');
    }
  }

  final String code;
  final String name;
  final List<Flag> flags;
  Flag get currentFlag => flags.singleWhere((flag) => flag.endYear == null);
}
