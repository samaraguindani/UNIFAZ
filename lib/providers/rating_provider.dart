import 'package:flutter/material.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';

class RatingProvider extends ChangeNotifier {
  final RatingService _ratingService = RatingService();

  List<Rating> _ratings = [];
  RatingStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  List<Rating> get ratings => _ratings;
  RatingStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRatingsByUserId(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _ratings = await _ratingService.getRatingsByUserId(userId);
      _stats = RatingStats.fromRatings(_ratings);
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao carregar avaliações');
      _setLoading(false);
    }
  }

  Future<void> loadRatingsByServiceId(String serviceId) async {
    _setLoading(true);
    _clearError();

    try {
      _ratings = await _ratingService.getRatingsByServiceId(serviceId);
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao carregar avaliações');
      _setLoading(false);
    }
  }

  Future<bool> createRating(Rating rating) async {
    _setLoading(true);
    _clearError();

    try {
      await _ratingService.createRating(rating);
      await loadRatingsByUserId(rating.toUserId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erro ao criar avaliação');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateRating(Rating rating) async {
    _setLoading(true);
    _clearError();

    try {
      await _ratingService.updateRating(rating);
      await loadRatingsByUserId(rating.toUserId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erro ao atualizar avaliação');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteRating(String ratingId) async {
    _setLoading(true);
    _clearError();

    try {
      await _ratingService.deleteRating(ratingId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erro ao excluir avaliação');
      _setLoading(false);
      return false;
    }
  }

  Future<Rating?> getExistingRating({
    required String fromUserId,
    required String toUserId,
    String? serviceId,
    String? requestId,
  }) async {
    try {
      return await _ratingService.getRatingByUsersAndService(
        fromUserId: fromUserId,
        toUserId: toUserId,
        serviceId: serviceId,
        requestId: requestId,
      );
    } catch (e) {
      return null;
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






