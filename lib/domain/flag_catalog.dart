import 'flag_item.dart';

abstract interface class FlagCatalog {
  Future<List<FlagItem>> loadFlags();
}
