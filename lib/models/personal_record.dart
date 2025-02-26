// lib/models/personal_record.dart
class PersonalRecord {
  final String exerciseId;
  final String exerciseName;
  final String recordType; // e.g., "Max Weight", "Max Reps", "Volume"
  final double value;
  final DateTime date;
  final String logId; // Reference to the log entry that set this record

  PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.recordType,
    required this.value,
    required this.date,
    required this.logId,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'recordType': recordType,
      'value': value,
      'date': date.toIso8601String(),
      'logId': logId,
    };
  }

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      exerciseId: json['exerciseId'],
      exerciseName: json['exerciseName'],
      recordType: json['recordType'],
      value: json['value'].toDouble(),
      date: DateTime.parse(json['date']),
      logId: json['logId'],
    );
  }
}
