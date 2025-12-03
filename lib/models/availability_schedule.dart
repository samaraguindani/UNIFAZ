import 'time_slot.dart';

class AvailabilitySchedule {
  final String? id;
  final String serviceId;
  final List<TimeSlot> timeSlots;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AvailabilitySchedule({
    this.id,
    required this.serviceId,
    required this.timeSlots,
    this.createdAt,
    this.updatedAt,
  });

  factory AvailabilitySchedule.fromJson(Map<String, dynamic> json) {
    return AvailabilitySchedule(
      id: json['id'] as String?,
      serviceId: json['service_id'] as String,
      timeSlots: (json['time_slots'] as List<dynamic>?)
              ?.map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final json = <String, dynamic>{
      'service_id': serviceId,
      'time_slots': timeSlots.map((slot) => slot.toJson()).toList(),
    };

    if (!forInsert && id != null) {
      json['id'] = id;
    }

    if (!forInsert) {
      if (createdAt != null) {
        json['created_at'] = createdAt!.toIso8601String();
      }
      if (updatedAt != null) {
        json['updated_at'] = updatedAt!.toIso8601String();
      }
    }

    return json;
  }

  // Converte para formato de texto legível
  String toDisplayString() {
    if (timeSlots.isEmpty) {
      return 'Sem horários definidos';
    }

    // Agrupa por dia da semana
    final Map<int, List<TimeSlot>> groupedByDay = {};
    for (var slot in timeSlots) {
      if (!groupedByDay.containsKey(slot.dayOfWeek)) {
        groupedByDay[slot.dayOfWeek] = [];
      }
      groupedByDay[slot.dayOfWeek]!.add(slot);
    }

    final List<String> parts = [];
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    groupedByDay.forEach((day, slots) {
      final dayName = days[day];
      final timeRanges = slots
          .map((s) => '${s.startTime}-${s.endTime}')
          .join(', ');
      parts.add('$dayName: $timeRanges');
    });

    return parts.join(' | ');
  }

  AvailabilitySchedule copyWith({
    String? id,
    String? serviceId,
    List<TimeSlot>? timeSlots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilitySchedule(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      timeSlots: timeSlots ?? this.timeSlots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Presets de horários comuns
class AvailabilityPresets {
  static List<TimeSlot> get weekdayBusinessHours {
    return [
      TimeSlot(dayOfWeek: 1, startTime: '08:00', endTime: '18:00'), // Segunda
      TimeSlot(dayOfWeek: 2, startTime: '08:00', endTime: '18:00'), // Terça
      TimeSlot(dayOfWeek: 3, startTime: '08:00', endTime: '18:00'), // Quarta
      TimeSlot(dayOfWeek: 4, startTime: '08:00', endTime: '18:00'), // Quinta
      TimeSlot(dayOfWeek: 5, startTime: '08:00', endTime: '18:00'), // Sexta
    ];
  }

  static List<TimeSlot> get weekendHours {
    return [
      TimeSlot(dayOfWeek: 6, startTime: '09:00', endTime: '17:00'), // Sábado
      TimeSlot(dayOfWeek: 0, startTime: '09:00', endTime: '17:00'), // Domingo
    ];
  }

  static List<TimeSlot> get fullWeek {
    return [
      ...weekdayBusinessHours,
      ...weekendHours,
    ];
  }

  static List<TimeSlot> get morningOnly {
    return [
      TimeSlot(dayOfWeek: 1, startTime: '08:00', endTime: '12:00'),
      TimeSlot(dayOfWeek: 2, startTime: '08:00', endTime: '12:00'),
      TimeSlot(dayOfWeek: 3, startTime: '08:00', endTime: '12:00'),
      TimeSlot(dayOfWeek: 4, startTime: '08:00', endTime: '12:00'),
      TimeSlot(dayOfWeek: 5, startTime: '08:00', endTime: '12:00'),
    ];
  }

  static List<TimeSlot> get afternoonOnly {
    return [
      TimeSlot(dayOfWeek: 1, startTime: '13:00', endTime: '18:00'),
      TimeSlot(dayOfWeek: 2, startTime: '13:00', endTime: '18:00'),
      TimeSlot(dayOfWeek: 3, startTime: '13:00', endTime: '18:00'),
      TimeSlot(dayOfWeek: 4, startTime: '13:00', endTime: '18:00'),
      TimeSlot(dayOfWeek: 5, startTime: '13:00', endTime: '18:00'),
    ];
  }

  static List<TimeSlot> get eveningOnly {
    return [
      TimeSlot(dayOfWeek: 1, startTime: '18:00', endTime: '22:00'),
      TimeSlot(dayOfWeek: 2, startTime: '18:00', endTime: '22:00'),
      TimeSlot(dayOfWeek: 3, startTime: '18:00', endTime: '22:00'),
      TimeSlot(dayOfWeek: 4, startTime: '18:00', endTime: '22:00'),
      TimeSlot(dayOfWeek: 5, startTime: '18:00', endTime: '22:00'),
    ];
  }

  static Map<String, List<TimeSlot>> get allPresets => {
    'Segunda a Sexta (8h-18h)': weekdayBusinessHours,
    'Fins de Semana (9h-17h)': weekendHours,
    'Semana Completa': fullWeek,
    'Apenas Manhãs (8h-12h)': morningOnly,
    'Apenas Tardes (13h-18h)': afternoonOnly,
    'Apenas Noites (18h-22h)': eveningOnly,
  };
}






