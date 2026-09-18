import 'package:allflag/domain/flag_id.dart';

FlagId flagId(String code) =>
    FlagId(FlagCategory.country, code.isEmpty ? 'invalid' : code);
