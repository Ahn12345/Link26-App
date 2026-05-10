class Medication {
  final String id;
  final String name;
  final String englishName;
  final String dose;
  final String frequency;
  final String time;
  final bool completed;

  const Medication({
    required this.id,
    required this.name,
    required this.englishName,
    required this.dose,
    required this.frequency,
    required this.time,
    this.completed = false,
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        englishName: json['englishName'] ?? '',
        dose: json['dose'] ?? '',
        frequency: json['frequency'] ?? '',
        time: json['time'] ?? '',
        completed: json['completed'] ?? false,
      );
}

class MedicineAlarm {
  final String id;
  final String dateLabel;
  final String time;
  final String type; // alarm, call, completed
  final String medicineName;
  final String dose;
  final String status; // 예정, 완료, 복용 완료

  const MedicineAlarm({
    required this.id,
    required this.dateLabel,
    required this.time,
    required this.type,
    required this.medicineName,
    required this.dose,
    required this.status,
  });
}

class FamilyMember {
  final String name;
  final String relation;
  final String phone;
  final String avatarText;

  const FamilyMember({
    required this.name,
    required this.relation,
    required this.phone,
    required this.avatarText,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final String? cardTitle;
  final String? cardSubtitle;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.cardTitle,
    this.cardSubtitle,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'time': time,
        if (cardTitle != null) 'cardTitle': cardTitle,
        if (cardSubtitle != null) 'cardSubtitle': cardSubtitle,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        time: json['time'] as String? ?? '',
        cardTitle: json['cardTitle'] as String?,
        cardSubtitle: json['cardSubtitle'] as String?,
      );
}
