import 'package:equatable/equatable.dart';

class Account extends Equatable {
  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props =>
      [id, userId, name, color, createdAt, updatedAt];
}
