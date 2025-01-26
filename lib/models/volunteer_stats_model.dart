import '../models/badge_model.dart';

class VolunteerStats {
  final String volunteerId;
  final int totalHelps;
  final int totalMinutesHelped;
  final double averageRating;
  final List<Badge> earnedBadges;
  final int currentLevel;
  final int experiencePoints;

  VolunteerStats({
    required this.volunteerId,
    required this.totalHelps,
    required this.totalMinutesHelped,
    required this.averageRating,
    required this.earnedBadges,
    required this.currentLevel,
    required this.experiencePoints,
  });

  factory VolunteerStats.fromJson(Map<String, dynamic> json) {
    return VolunteerStats(
      volunteerId: json['volunteerId'] as String,
      totalHelps: json['totalHelps'] as int,
      totalMinutesHelped: json['totalMinutesHelped'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      earnedBadges: ((json['earnedBadges'] as List?) ?? [])
          .map((badge) => Badge.fromJson(badge as Map<String, dynamic>))
          .toList(),
      currentLevel: json['currentLevel'] as int,
      experiencePoints: json['experiencePoints'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volunteerId': volunteerId,
      'totalHelps': totalHelps,
      'totalMinutesHelped': totalMinutesHelped,
      'averageRating': averageRating,
      'earnedBadges': earnedBadges.map((badge) => badge.toJson()).toList(),
      'currentLevel': currentLevel,
      'experiencePoints': experiencePoints,
    };
  }

  VolunteerStats copyWith({
    String? volunteerId,
    int? totalHelps,
    int? totalMinutesHelped,
    double? averageRating,
    List<Badge>? earnedBadges,
    int? currentLevel,
    int? experiencePoints,
  }) {
    return VolunteerStats(
      volunteerId: volunteerId ?? this.volunteerId,
      totalHelps: totalHelps ?? this.totalHelps,
      totalMinutesHelped: totalMinutesHelped ?? this.totalMinutesHelped,
      averageRating: averageRating ?? this.averageRating,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      currentLevel: currentLevel ?? this.currentLevel,
      experiencePoints: experiencePoints ?? this.experiencePoints,
    );
  }
}
