/// A design and its period of use. A null startYear means not yet researched;
/// a null endYear means still in use.
class Flag {
  const Flag({
    required this.id,
    required this.name,
    required this.asset,
    this.startYear,
    this.endYear,
  }) : assert(startYear == null || endYear == null || endYear >= startYear);

  final String id;
  final String name;
  final String asset;
  final int? startYear;
  final int? endYear;
}
