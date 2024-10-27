import 'package:hive/hive.dart';

part 'equipment_model.g.dart';

@HiveType(typeId: 0)
class Equipment extends HiveObject {
  @HiveField(0)
  final String serialNumber;

  @HiveField(1)
  String location;

  @HiveField(2)
  String notes;

  Equipment({
    required this.serialNumber,
    this.location = '',
    this.notes = '',
  });

  Map<String, String> toMap() {
    return {
      'Serial Number': serialNumber,
      'Location': location,
      'Notes': notes,
    };
  }

  String toCsv() {
    return '"$serialNumber","$location","$notes"';
  }
}

// Run the following command to generate the Hive adapter:
// flutter packages pub run build_runner build
