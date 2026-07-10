// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculation_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalculationHistoryAdapter extends TypeAdapter<CalculationHistory> {
  @override
  final int typeId = 0;

  @override
  CalculationHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalculationHistory(
      id: fields[0] as String,
      calculatorId: fields[1] as String,
      calculatorName: fields[2] as String,
      category: fields[3] as String,
      inputs: (fields[4] as Map).cast<String, dynamic>(),
      results: (fields[5] as Map).cast<String, dynamic>(),
      timestamp: fields[6] as DateTime,
      summary: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CalculationHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.calculatorId)
      ..writeByte(2)
      ..write(obj.calculatorName)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.inputs)
      ..writeByte(5)
      ..write(obj.results)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.summary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
