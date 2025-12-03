enum NotificationType {
  appointmentRequest('Solicitação de Agendamento'),
  appointmentApproved('Agendamento Aprovado'),
  appointmentRejected('Agendamento Rejeitado'),
  appointmentCancelled('Agendamento Cancelado');

  final String displayName;
  const NotificationType(this.displayName);
}

class AppNotification {
  final String id;
  final String userId; // Usuário que recebe a notificação
  final String fromUserId; // Usuário que gerou a notificação
  final NotificationType type;
  final String title;
  final String message;
  final String? appointmentId; // ID do agendamento relacionado
  final String? serviceId; // ID do serviço relacionado
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.fromUserId,
    required this.type,
    required this.title,
    required this.message,
    this.appointmentId,
    this.serviceId,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fromUserId: json['from_user_id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.appointmentRequest,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      appointmentId: json['appointment_id'] as String?,
      serviceId: json['service_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final Map<String, dynamic> json = {
      'user_id': userId,
      'from_user_id': fromUserId,
      'type': type.name,
      'title': title,
      'message': message,
      'is_read': isRead,
    };

    if (appointmentId != null) {
      json['appointment_id'] = appointmentId;
    }

    if (serviceId != null) {
      json['service_id'] = serviceId;
    }

    if (readAt != null) {
      json['read_at'] = readAt!.toIso8601String();
    }

    if (!forInsert) {
      json['id'] = id;
      json['created_at'] = createdAt.toIso8601String();
    }

    return json;
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? fromUserId,
    NotificationType? type,
    String? title,
    String? message,
    String? appointmentId,
    String? serviceId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromUserId: fromUserId ?? this.fromUserId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      appointmentId: appointmentId ?? this.appointmentId,
      serviceId: serviceId ?? this.serviceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}


