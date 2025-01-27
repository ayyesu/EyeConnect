import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry_model.dart';
import 'package:logger/logger.dart';

class LeaderboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = false;
  final Logger _logger = Logger();
  String _error = '';

  List<LeaderboardEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchLeaderboard() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final snapshot = await _firestore
          .collection('leaderboard')
          .orderBy('helpCount', descending: true)
          .orderBy('averageRating', descending: true)
          .limit(10) // Only get top 10
          .get();

      _entries = snapshot.docs
          .map((doc) => LeaderboardEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Failed to fetch leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVolunteerStats(
    String userId, {
    required int callDuration,
    required double rating,
  }) async {
    try {
      // Update leaderboard collection
      final docRef = _firestore.collection('leaderboard').doc(userId);
      final doc = await docRef.get();

      // Get user data for both collections
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data()!;

      if (doc.exists) {
        final currentData = doc.data()!;
        final currentCount = currentData['helpCount'] ?? 0;
        final currentTotalRating =
            (currentData['averageRating'] ?? 5.0) * currentCount;
        final currentTotalTime = currentData['totalHelpTimeMinutes'] ?? 0;

        // Calculate new values
        final newCount = currentCount + 1;
        final newAverageRating = (currentTotalRating + rating) / newCount;
        final newTotalTime = currentTotalTime + callDuration;

        // Update leaderboard
        await docRef.update({
          'helpCount': newCount,
          'averageRating': newAverageRating,
          'totalHelpTimeMinutes': newTotalTime,
        });

        // Update volunteer_stats collection
        await _firestore.collection('volunteer_stats').doc(userId).set({
          'volunteerId': userId,
          'userName': userData['username'],
          'totalHelps': newCount,
          'totalMinutesHelped': newTotalTime,
          'averageRating': newAverageRating,
          'earnedBadges': currentData['earnedBadges'] ?? [],
          'currentLevel': currentData['currentLevel'] ?? 1,
          'experiencePoints': currentData['experiencePoints'] ?? 0,
        }, SetOptions(merge: true));
      } else {
        // First entry for this volunteer - initialize both collections
        final initialData = {
          'userId': userId,
          'userName': userData['username'],
          'helpCount': 1,
          'averageRating': rating,
          'totalHelpTimeMinutes': callDuration,
        };

        // Initialize leaderboard entry
        await docRef.set(initialData);

        // Initialize volunteer_stats entry
        await _firestore.collection('volunteer_stats').doc(userId).set({
          'volunteerId': userId,
          'userName': userData['username'],
          'totalHelps': 1,
          'totalMinutesHelped': callDuration,
          'averageRating': rating,
          'earnedBadges': [],
          'currentLevel': 1,
          'experiencePoints': 0,
        });
      }

      // Refresh leaderboard after update
      await fetchLeaderboard();
    } catch (e) {
      _error = 'Failed to update volunteer stats: $e';
      _logger.e(_error);
      notifyListeners();
    }
  }
}
