import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadNotifications(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _notifications = await _notificationService.getNotificationsByUserId(userId);
      _unreadCount = await _notificationService.getUnreadCount(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao carregar notificações');
      _setLoading(false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      _setError('Erro ao marcar notificação como lida');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);
      _notifications = _notifications.map((n) => n.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao marcar todas como lidas');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao excluir notificação');
    }
  }

  Future<void> refreshUnreadCount(String userId) async {
    try {
      _unreadCount = await _notificationService.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      // Silenciar erro
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}


