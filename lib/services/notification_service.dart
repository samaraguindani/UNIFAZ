import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AppNotification>> getNotificationsByUserId(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppNotification>> getUnreadNotificationsByUserId(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_unread_notifications_count',
        params: {'user_uuid': userId},
      );
      return response as int;
    } catch (e) {
      // Fallback: contar manualmente
      final notifications = await getUnreadNotificationsByUserId(userId);
      return notifications.length;
    }
  }

  Future<AppNotification> createNotification(AppNotification notification) async {
    final response = await _supabase
        .from('notifications')
        .insert(notification.toJson(forInsert: true))
        .select()
        .single();

    return AppNotification.fromJson(response as Map<String, dynamic>);
  }

  Future<AppNotification> markAsRead(String notificationId) async {
    final response = await _supabase
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId)
        .select()
        .single();

    return AppNotification.fromJson(response as Map<String, dynamic>);
  }

  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _supabase.from('notifications').delete().eq('id', notificationId);
  }

  Future<AppNotification?> getNotificationById(String notificationId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('id', notificationId)
          .single();

      return AppNotification.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}


