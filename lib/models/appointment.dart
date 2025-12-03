enum AppointmentStatus {
  pending('Pendente'),
  confirmed('Confirmado'),
  cancelled('Cancelado'),
  completed('Concluído');

  final String displayName;
  const AppointmentStatus(this.displayName);
}

class Appointment {
  final String id;
  final String serviceId;
  final String clientId; // Usuário que está agendando
  final String providerId; // Prestador do serviço
  final DateTime appointmentDate; // Data do agendamento
  final String startTime; // Horário de início (HH:mm)
  final String endTime; // Horário de fim (HH:mm)
  final String? notes; // Observações do cliente
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.providerId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      clientId: json['client_id'] as String,
      providerId: json['provider_id'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      notes: json['notes'] as String?,
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final Map<String, dynamic> json = {
      'service_id': serviceId,
      'client_id': clientId,
      'provider_id': providerId,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0], // Apenas a data
      'start_time': startTime,
      'end_time': endTime,
      'status': status.name,
    };

    if (notes != null && notes!.isNotEmpty) {
      json['notes'] = notes;
    }

    if (!forInsert) {
      json['id'] = id;
      json['created_at'] = createdAt.toIso8601String();
      json['updated_at'] = updatedAt.toIso8601String();
    }

    return json;
  }

  Appointment copyWith({
    String? id,
    String? serviceId,
    String? clientId,
    String? providerId,
    DateTime? appointmentDate,
    String? startTime,
    String? endTime,
    String? notes,
    AppointmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      clientId: clientId ?? this.clientId,
      providerId: providerId ?? this.providerId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Retorna a data e hora completa do início do agendamento
  DateTime get startDateTime {
    final timeParts = startTime.split(':');
    return DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  // Retorna a data e hora completa do fim do agendamento
  DateTime get endDateTime {
    final timeParts = endTime.split(':');
    return DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }
}






