class TimeSlot {
  final int dayOfWeek; // 0 = Domingo, 1 = Segunda, ..., 6 = Sábado
  final String startTime; // Formato HH:mm
  final String endTime; // Formato HH:mm

  TimeSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  String get dayName {
    const days = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
    return days[dayOfWeek];
  }

  TimeSlot copyWith({
    int? dayOfWeek,
    String? startTime,
    String? endTime,
  }) {
    return TimeSlot(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot &&
        other.dayOfWeek == dayOfWeek &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => dayOfWeek.hashCode ^ startTime.hashCode ^ endTime.hashCode;
}






