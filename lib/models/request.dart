import 'package:hive/hive.dart';

part 'request.g.dart';

@HiveType(typeId: 0)
class RequestItem {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String contractor;
  @HiveField(4)
  final String serviceType;
  @HiveField(5)
  final String durationLabel;
  @HiveField(6)
  final double revenue;
  @HiveField(7)
  final double cost;
  @HiveField(8)
  final bool isDone;

  RequestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.contractor,
    required this.serviceType,
    required this.durationLabel,
    required this.revenue,
    required this.cost,
    this.isDone = false,
  });
}
