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
    required Duration callDuration,
    required double rating,
  }) async {
    try {
      final docRef = _firestore.collection('leaderboard').doc(userId);
      final doc = await docRef.get();

      if (doc.exists) {
        final currentData = doc.data()!;
        final currentCount = currentData['helpCount'] ?? 0;
        final currentTotalRating =
            (currentData['averageRating'] ?? 5.0) * currentCount;
        final currentTotalTime = currentData['totalHelpTimeMinutes'] ?? 0;

        // Calculate new values
        final newCount = currentCount + 1;
        final newAverageRating = (currentTotalRating + rating) / newCount;
        final newTotalTime = currentTotalTime + callDuration.inMinutes;

        await docRef.update({
          'helpCount': newCount,
          'averageRating': newAverageRating,
          'totalHelpTimeMinutes': newTotalTime,
        });
      } else {
        // Create new entry for first-time volunteer
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data()!;

        await docRef.set({
          'userId': userId,
          'userName': userData['username'],
          'helpCount': 1,
          'averageRating': rating,
          'totalHelpTimeMinutes': callDuration.inMinutes,
        });
      }

      // Refresh leaderboard after update
      await fetchLeaderboard();
    } catch (e) {
      _error = 'Failed to update volunteer stats: $e';
      notifyListeners();
    }
  }
}
