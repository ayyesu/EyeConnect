import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer_stats_model.dart';
import '../models/badge_model.dart';
import 'badge_service.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BadgeService _badgeService = BadgeService();

  Future<void> initializeVolunteerStats(String volunteerId) async {
    final statsRef = _firestore.collection('volunteer_stats').doc(volunteerId);
    final statsDoc = await statsRef.get();

    if (!statsDoc.exists) {
      await statsRef.set({
        'volunteerId': volunteerId,
        'totalHelps': 0,
        'totalMinutesHelped': 0,
        'averageRating': 0.0,
        'earnedBadges': [],
        'currentLevel': 1,
        'experiencePoints': 0,
      });
    }
  }

  Future<void> updateStats(
    String volunteerId, {
    int? additionalHelps,
    int? additionalMinutes,
    double? rating,
  }) async {
    final statsRef = _firestore.collection('volunteer_stats').doc(volunteerId);
    final statsDoc = await statsRef.get();

    if (!statsDoc.exists) {
      await initializeVolunteerStats(volunteerId);
    }

    final data = statsDoc.data() as Map<String, dynamic>;
    final currentStats = VolunteerStats.fromJson(data);

    final newTotalHelps = currentStats.totalHelps + (additionalHelps ?? 0);
    final newTotalMinutes =
        currentStats.totalMinutesHelped + (additionalMinutes ?? 0);

    // Calculate new average rating if a rating is provided
    double newAverageRating = currentStats.averageRating;
    if (rating != null) {
      newAverageRating =
          ((currentStats.averageRating * currentStats.totalHelps) + rating) /
              (currentStats.totalHelps + 1);
    }

    // Calculate experience points (simple formula)
    final newXP = currentStats.experiencePoints + (additionalHelps ?? 0) * 10;
    final newLevel = (newXP / 100).floor() + 1;

    // Check and award new badges
    final newBadges = await _badgeService.checkAndAwardBadges(volunteerId, newTotalHelps);

    // Check for time-based badges
    if (newTotalMinutes >= 100) {
      final timeMasterBadge = await _getTimeMasterBadge();
      if (timeMasterBadge != null && !currentStats.earnedBadges.any((b) => b.id == 'time_master')) {
        await _badgeService.awardBadge(volunteerId, timeMasterBadge.id);
        newBadges.add(timeMasterBadge);
      }
    }

    // Get updated list of all earned badges
    final allEarnedBadges = await _badgeService.getUserBadges(volunteerId);

    await statsRef.update({
      'totalHelps': newTotalHelps,
      'totalMinutesHelped': newTotalMinutes,
      'averageRating': newAverageRating,
      'earnedBadges': allEarnedBadges.map((b) => b.toJson()).toList(),
      'currentLevel': newLevel,
      'experiencePoints': newXP,
    });

    // Return newly earned badges if needed for notifications
    if (newBadges.isNotEmpty) {
      // You could emit an event or handle notifications here
      print('New badges earned: ${newBadges.map((b) => b.name).join(', ')}');
    }
  }

  Future<Badge?> _getTimeMasterBadge() async {
    final badges = await _badgeService.getAllBadges();
    return badges.firstWhere(
      (b) => b.id == 'time_master',
      orElse: () => throw Exception('Time Master badge not found in database'),
    );
  }

  Future<List<Badge>> getVolunteerBadges(String volunteerId) async {
    return await _badgeService.getUserBadges(volunteerId);
  }

  Future<VolunteerStats> getVolunteerStats(String volunteerId) async {
    final statsDoc = await _firestore.collection('volunteer_stats').doc(volunteerId).get();
    
    if (!statsDoc.exists) {
      await initializeVolunteerStats(volunteerId);
      return VolunteerStats(
        volunteerId: volunteerId,
        totalHelps: 0,
        totalMinutesHelped: 0,
        averageRating: 0.0,
        earnedBadges: [],
        currentLevel: 1,
        experiencePoints: 0,
      );
    }

    return VolunteerStats.fromJson(statsDoc.data() as Map<String, dynamic>);
  }
}
