class Rating {
  final String id;
  final String fromUserId; // Usuário que está avaliando
  final String toUserId; // Usuário sendo avaliado
  final String? serviceId; // Serviço relacionado (opcional)
  final String? requestId; // Demanda relacionada (opcional)
  final int rating; // Nota de 1 a 5
  final String? comment; // Comentário opcional
  final DateTime createdAt;
  final DateTime updatedAt;

  Rating({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.serviceId,
    this.requestId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      serviceId: json['service_id'] as String?,
      requestId: json['request_id'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final Map<String, dynamic> json = {
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'rating': rating,
    };

    if (serviceId != null) {
      json['service_id'] = serviceId;
    }

    if (requestId != null) {
      json['request_id'] = requestId;
    }

    if (comment != null && comment!.isNotEmpty) {
      json['comment'] = comment;
    }

    if (!forInsert) {
      json['id'] = id;
      json['created_at'] = createdAt.toIso8601String();
      json['updated_at'] = updatedAt.toIso8601String();
    }

    return json;
  }

  Rating copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? serviceId,
    String? requestId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rating(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      serviceId: serviceId ?? this.serviceId,
      requestId: requestId ?? this.requestId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Classe auxiliar para estatísticas de avaliação
class RatingStats {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // {1: 5, 2: 3, 3: 10, 4: 20, 5: 50}

  RatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  factory RatingStats.fromRatings(List<Rating> ratings) {
    if (ratings.isEmpty) {
      return RatingStats(
        averageRating: 0.0,
        totalRatings: 0,
        ratingDistribution: {},
      );
    }

    final distribution = <int, int>{};
    double sum = 0;

    for (var rating in ratings) {
      distribution[rating.rating] = (distribution[rating.rating] ?? 0) + 1;
      sum += rating.rating;
    }

    return RatingStats(
      averageRating: sum / ratings.length,
      totalRatings: ratings.length,
      ratingDistribution: distribution,
    );
  }
}






