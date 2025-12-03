import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/notification.dart';
import '../models/appointment.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../services/appointment_service.dart';
import '../services/notification_service.dart';
import '../widgets/common_widgets.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.loadNotifications(authProvider.currentUser!.id);
    }
  }

  Future<void> _handleAppointmentAction(
      AppNotification notification, bool approve) async {
    if (notification.appointmentId == null) return;

    try {
      final appointment = await _appointmentService
          .getAppointmentById(notification.appointmentId!);
      if (appointment == null) return;

      final newStatus = approve
          ? AppointmentStatus.confirmed
          : AppointmentStatus.cancelled;

      final updated = appointment.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await _appointmentService.updateAppointment(updated);

      // Criar notificação para o cliente
      final authProvider = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      final clientNotification = AppNotification(
        id: '',
        userId: notification.fromUserId,
        fromUserId: authProvider.currentUser!.id,
        type: approve
            ? NotificationType.appointmentApproved
            : NotificationType.appointmentRejected,
        title: approve
            ? 'Agendamento Aprovado'
            : 'Agendamento Rejeitado',
        message: approve
            ? 'Seu agendamento foi aprovado pelo prestador'
            : 'Seu agendamento foi rejeitado pelo prestador',
        appointmentId: appointment.id,
        serviceId: appointment.serviceId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _notificationService.createNotification(clientNotification);

      // Marcar notificação atual como lida
      await notificationProvider.markAsRead(notification.id);

      // Recarregar notificações
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Agendamento aprovado com sucesso!'
                  : 'Agendamento rejeitado',
            ),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar ação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: const Color(0xFF5a7a6a),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.currentUser != null) {
                      await provider.markAllAsRead(authProvider.currentUser!.id);
                    }
                  },
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  label: Text(
                    'Marcar todas como lidas',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingWidget());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationCard(notification, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
      AppNotification notification, NotificationProvider provider) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnread
            ? const BorderSide(color: Color(0xFF87a492), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          // Ver perfil do usuário que gerou a notificação
          if (notification.type == NotificationType.appointmentRequest) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: notification.fromUserId,
                ),
              ),
            );
          }

          // Marcar como lida
          if (!notification.isRead) {
            await provider.markAsRead(notification.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF87a492),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateFormat.format(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Ações para solicitação de agendamento
              if (notification.type == NotificationType.appointmentRequest &&
                  notification.appointmentId != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleAppointmentAction(
                            notification, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Rejeitar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _handleAppointmentAction(notification, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aprovar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentRequest:
        return Colors.blue;
      case NotificationType.appointmentApproved:
        return Colors.green;
      case NotificationType.appointmentRejected:
        return Colors.red;
      case NotificationType.appointmentCancelled:
        return Colors.orange;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentRequest:
        return Icons.calendar_today;
      case NotificationType.appointmentApproved:
        return Icons.check_circle;
      case NotificationType.appointmentRejected:
        return Icons.cancel;
      case NotificationType.appointmentCancelled:
        return Icons.event_busy;
    }
  }
}


