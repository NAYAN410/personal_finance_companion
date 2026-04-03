import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 2)
class Goal {
  @HiveField(0)
  double targetAmount;
  @HiveField(1)
  DateTime month;

  Goal({required this.targetAmount, required this.month});
}