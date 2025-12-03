import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/availability_schedule.dart';
import '../models/time_slot.dart';

class AvailabilityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AvailabilitySchedule?> getAvailabilityByServiceId(String serviceId) async {
    try {
      final response = await _supabase
          .from('service_availability')
          .select()
          .eq('service_id', serviceId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final timeSlotsJson = response['time_slots'] as List<dynamic>;
      final timeSlots = timeSlotsJson
          .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
          .toList();

      return AvailabilitySchedule(
        id: response['id'] as String,
        serviceId: serviceId,
        timeSlots: timeSlots,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      print('Erro ao buscar disponibilidade: $e');
      return null;
    }
  }

  Future<AvailabilitySchedule> createOrUpdateAvailability(
      AvailabilitySchedule schedule) async {
    final scheduleData = {
      'service_id': schedule.serviceId,
      'time_slots': schedule.timeSlots.map((slot) => slot.toJson()).toList(),
    };

    try {
      // Tentar atualizar primeiro
      final updateResponse = await _supabase
          .from('service_availability')
          .update(scheduleData)
          .eq('service_id', schedule.serviceId)
          .select()
          .maybeSingle();

      if (updateResponse != null) {
        final timeSlotsJson = updateResponse['time_slots'] as List<dynamic>;
        final timeSlots = timeSlotsJson
            .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
            .toList();

        return AvailabilitySchedule(
          id: updateResponse['id'] as String,
          serviceId: schedule.serviceId,
          timeSlots: timeSlots,
          createdAt: DateTime.parse(updateResponse['created_at'] as String),
          updatedAt: DateTime.parse(updateResponse['updated_at'] as String),
        );
      }

      // Se não existir, criar
      final insertResponse = await _supabase
          .from('service_availability')
          .insert(scheduleData)
          .select()
          .single();

      final timeSlotsJson = insertResponse['time_slots'] as List<dynamic>;
      final timeSlots = timeSlotsJson
          .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
          .toList();

      return AvailabilitySchedule(
        id: insertResponse['id'] as String,
        serviceId: schedule.serviceId,
        timeSlots: timeSlots,
        createdAt: DateTime.parse(insertResponse['created_at'] as String),
        updatedAt: DateTime.parse(insertResponse['updated_at'] as String),
      );
    } catch (e) {
      print('Erro ao salvar disponibilidade: $e');
      rethrow;
    }
  }

  Future<void> deleteAvailability(String serviceId) async {
    await _supabase
        .from('service_availability')
        .delete()
        .eq('service_id', serviceId);
  }
}


