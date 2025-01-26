import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/volunteer_stats_model.dart';
import '../models/badge_model.dart' as badge_model;
import '../services/badge_service.dart';

class VolunteerProfileScreen extends StatelessWidget {
  const VolunteerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Profile'),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('volunteer_stats')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No stats available'));
          }

          final statsData = snapshot.data!.data() as Map<String, dynamic>;
          final stats = VolunteerStats.fromJson({
            ...statsData,
            'volunteerId': FirebaseAuth.instance.currentUser?.uid ?? '',
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCard(stats),
                const SizedBox(height: 20),
                _buildLevelProgress(stats),
                const SizedBox(height: 20),
                _buildBadgesSection(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(VolunteerStats stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Impact',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Total Helps',
              '${stats.totalHelps}',
              Icons.volunteer_activism,
            ),
            _buildStatRow(
              'Minutes Helped',
              '${stats.totalMinutesHelped}',
              Icons.timer,
            ),
            _buildStatRow(
              'Average Rating',
              '${stats.averageRating.toStringAsFixed(1)} / 5.0',
              Icons.star,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(VolunteerStats stats) {
    final nextLevelXP = stats.currentLevel * 100;
    final progress = stats.experiencePoints / nextLevelXP;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level ${stats.currentLevel}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${stats.experiencePoints} / $nextLevelXP XP',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(VolunteerStats stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earned Badges',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (stats.earnedBadges.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No badges earned yet. Keep helping to earn badges!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: stats.earnedBadges.length,
                itemBuilder: (context, index) {
                  final badge = stats.earnedBadges[index];
                  return _buildBadgeItem(badge);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem(badge_model.Badge badge) {
    return FutureBuilder<List<int>?>(
      future: BadgeService().getBadgeImageData(badge.imageUrl),
      builder: (context, snapshot) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Tooltip(
            message: badge.description,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: snapshot.hasData
                        ? SvgPicture.memory(
                            Uint8List.fromList(snapshot.data!),
                            fit: BoxFit.contain,
                          )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
