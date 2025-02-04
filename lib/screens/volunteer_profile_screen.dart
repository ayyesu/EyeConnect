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
      body: FutureBuilder<VolunteerStats>(
        // For presentation, return mock data immediately
        future: Future.value(VolunteerStats(
          volunteerId: '1',
          totalHelps: 150,
          totalMinutesHelped: 450,
          averageRating: 4.9,
          earnedBadges: [
            badge_model.Badge(
              id: 'helper_badge',
              name: 'Super Helper',
              description: 'Helped 100+ people',
              imageUrl: 'assets/badges/super_helper.svg',
              requiredHelps: 100,
            ),
            badge_model.Badge(
              id: 'time_badge',
              name: 'Time Champion',
              description: 'Spent 400+ minutes helping',
              imageUrl: 'assets/badges/time_champion.svg',
              requiredHelps: 400,
            ),
            badge_model.Badge(
              id: 'rating_badge',
              name: 'Top Rated',
              description: 'Maintained 4.8+ rating',
              imageUrl: 'assets/badges/top_rated.svg',
              requiredHelps: 0,
            ),
          ],
          currentLevel: 5,
          experiencePoints: 2500,
        )),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No stats available'));
          }

          final stats = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCard(stats),
                const SizedBox(height: 20),
                _buildLevelProgress(stats),
                const SizedBox(height: 20),
                _buildBadgesSection(context, stats),
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

  Widget _buildBadgesSection(BuildContext context, VolunteerStats stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.military_tech, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Your Badges',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats.earnedBadges.isEmpty)
              const Center(
                child: Text(
                  'Start helping to earn badges!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: stats.earnedBadges.length,
                  itemBuilder: (context, index) {
                    return _buildBadgeCard(context, stats.earnedBadges[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, badge_model.Badge badge) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade100,
                    Colors.blue.shade50,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Image.asset(
                        _getBadgeImageUrl(badge.id),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.emoji_events,
                            size: 48,
                            color: Colors.amber,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          badge.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          badge.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBadgeImageUrl(String badgeId) {
    // Using local badge assets
    final badgeImages = {
      'helper_badge': 'assets/badges/Champion.png',
      'time_badge': 'assets/badges/Gold.png',
      'rating_badge': 'assets/badges/Master.png',
    };

    return badgeImages[badgeId] ??
        'assets/badges/Bronze.png'; // Default to Bronze badge
  }
}
