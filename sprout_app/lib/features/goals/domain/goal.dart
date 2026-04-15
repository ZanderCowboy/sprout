import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmountCents,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final int targetAmountCents;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props =>
      [id, userId, name, targetAmountCents, color, createdAt, updatedAt];
}
