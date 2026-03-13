import 'package:hive/hive.dart';

part 'contractor.g.dart';

@HiveType(typeId: 1)
class Contractor {
  @HiveField(0)
  final String name;

  Contractor({required this.name});
}
