import 'package:hive_flutter/hive_flutter.dart';

part 'calculation_history.g.dart';

@HiveType(typeId: 0)
class CalculationHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String calculatorId;

  @HiveField(2)
  final String calculatorName;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final Map<String, dynamic> inputs;

  @HiveField(5)
  final Map<String, dynamic> results;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final String summary;

  CalculationHistory({
    required this.id,
    required this.calculatorId,
    required this.calculatorName,
    required this.category,
    required this.inputs,
    required this.results,
    required this.timestamp,
    required this.summary,
  });

  CalculationHistory copyWith({
    String? id,
    String? calculatorId,
    String? calculatorName,
    String? category,
    Map<String, dynamic>? inputs,
    Map<String, dynamic>? results,
    DateTime? timestamp,
    String? summary,
  }) {
    return CalculationHistory(
      id: id ?? this.id,
      calculatorId: calculatorId ?? this.calculatorId,
      calculatorName: calculatorName ?? this.calculatorName,
      category: category ?? this.category,
      inputs: inputs ?? this.inputs,
      results: results ?? this.results,
      timestamp: timestamp ?? this.timestamp,
      summary: summary ?? this.summary,
    );
  }

  @override
  String toString() => 'CalculationHistory($calculatorName, $summary)';
}
