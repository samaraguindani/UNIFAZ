import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rating.dart';

class RatingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Rating>> getRatingsByUserId(String userId) async {
    final response = await _supabase
        .from('ratings')
        .select()
        .eq('to_user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Rating.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Rating>> getRatingsByServiceId(String serviceId) async {
    final response = await _supabase
        .from('ratings')
        .select()
        .eq('service_id', serviceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Rating.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Rating?> getRatingById(String ratingId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select()
          .eq('id', ratingId)
          .single();

      return Rating.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<Rating?> getRatingByUsersAndService({
    required String fromUserId,
    required String toUserId,
    String? serviceId,
    String? requestId,
  }) async {
    try {
      var query = _supabase
          .from('ratings')
          .select()
          .eq('from_user_id', fromUserId)
          .eq('to_user_id', toUserId);

      if (serviceId != null) {
        query = query.eq('service_id', serviceId);
      } else {
        query = query.isFilter('service_id', null);
      }

      if (requestId != null) {
        query = query.eq('request_id', requestId);
      } else {
        query = query.isFilter('request_id', null);
      }

      final response = await query.maybeSingle();

      if (response == null) {
        return null;
      }

      return Rating.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<Rating> createRating(Rating rating) async {
    final response = await _supabase
        .from('ratings')
        .insert(rating.toJson(forInsert: true))
        .select()
        .single();

    return Rating.fromJson(response as Map<String, dynamic>);
  }

  Future<Rating> updateRating(Rating rating) async {
    final response = await _supabase
        .from('ratings')
        .update(rating.toJson())
        .eq('id', rating.id)
        .select()
        .single();

    return Rating.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteRating(String ratingId) async {
    await _supabase.from('ratings').delete().eq('id', ratingId);
  }

  Future<RatingStats> getRatingStats(String userId) async {
    final ratings = await getRatingsByUserId(userId);
    return RatingStats.fromRatings(ratings);
  }
}






