import 'package:equatable/equatable.dart';

class PortfolioSummary extends Equatable {
  const PortfolioSummary({
    required this.totalCents,
    this.lastActivityAt,
  });

  final int totalCents;
  final DateTime? lastActivityAt;

  @override
  List<Object?> get props => [totalCents, lastActivityAt];
}
