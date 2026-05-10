enum AlarmType { app, call }

class AlarmItem {
  final String date;
  final String time;
  final String medicineName;
  final String dose;
  final AlarmType type;
  bool completed;

  AlarmItem({
    required this.date,
    required this.time,
    required this.medicineName,
    required this.dose,
    required this.type,
    this.completed = false,
  });
}
