import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Appointment>> getAppointmentsByServiceId(String serviceId) async {
    final response = await _supabase
        .from('appointments')
        .select()
        .eq('service_id', serviceId)
        .order('appointment_date', ascending: true)
        .order('start_time', ascending: true);

    return (response as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Appointment>> getAppointmentsByClientId(String clientId) async {
    final response = await _supabase
        .from('appointments')
        .select()
        .eq('client_id', clientId)
        .order('appointment_date', ascending: false)
        .order('start_time', ascending: false);

    return (response as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Appointment>> getAppointmentsByProviderId(String providerId) async {
    final response = await _supabase
        .from('appointments')
        .select()
        .eq('provider_id', providerId)
        .order('appointment_date', ascending: false)
        .order('start_time', ascending: false);

    return (response as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Appointment>> getAppointmentsByDateRange({
    required String serviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _supabase
        .from('appointments')
        .select()
        .eq('service_id', serviceId)
        .gte('appointment_date', startDate.toIso8601String().split('T')[0])
        .lte('appointment_date', endDate.toIso8601String().split('T')[0])
        .order('appointment_date', ascending: true)
        .order('start_time', ascending: true);

    return (response as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<bool> checkTimeSlotAvailable({
    required String serviceId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? excludeAppointmentId,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _supabase.rpc(
        'check_appointment_conflict',
        params: {
          'p_service_id': serviceId,
          'p_appointment_date': dateStr,
          'p_start_time': startTime,
          'p_end_time': endTime,
          'p_exclude_id': excludeAppointmentId,
        },
      );

      // Se retornar true, há conflito (não disponível)
      return !(response as bool);
    } catch (e) {
      // Em caso de erro, verificar manualmente
      final dateStr = date.toIso8601String().split('T')[0];
      final appointmentsResponse = await _supabase
          .from('appointments')
          .select()
          .eq('service_id', serviceId)
          .eq('appointment_date', dateStr)
          .neq('status', 'cancelled')
          .neq('status', 'completed');

      List<dynamic> appointments = appointmentsResponse as List<dynamic>;

      if (excludeAppointmentId != null) {
        // Filtrar o appointment excluído
        appointments = appointments
            .where((a) => (a as Map<String, dynamic>)['id'] != excludeAppointmentId)
            .toList();
      }

      for (var apt in appointments) {
        final aptMap = apt as Map<String, dynamic>;
        final aptStart = aptMap['start_time'] as String;
        final aptEnd = aptMap['end_time'] as String;

        // Verificar sobreposição
        if (_timesOverlap(startTime, endTime, aptStart, aptEnd)) {
          return false; // Conflito encontrado
        }
      }

      return true; // Sem conflitos
    }
  }

  bool _timesOverlap(String start1, String end1, String start2, String end2) {
    final s1 = _timeToMinutes(start1);
    final e1 = _timeToMinutes(end1);
    final s2 = _timeToMinutes(start2);
    final e2 = _timeToMinutes(end2);

    return s1 < e2 && e1 > s2;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<Appointment> createAppointment(Appointment appointment) async {
    final response = await _supabase
        .from('appointments')
        .insert(appointment.toJson(forInsert: true))
        .select()
        .single();

    return Appointment.fromJson(response as Map<String, dynamic>);
  }

  Future<Appointment> updateAppointment(Appointment appointment) async {
    final response = await _supabase
        .from('appointments')
        .update(appointment.toJson())
        .eq('id', appointment.id)
        .select()
        .single();

    return Appointment.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await _supabase.from('appointments').delete().eq('id', appointmentId);
  }

  Future<Appointment?> getAppointmentById(String appointmentId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('id', appointmentId)
          .single();

      return Appointment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}

