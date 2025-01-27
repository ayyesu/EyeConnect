import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/badge_model.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Create a singleton
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  // Get badge image URL from Dicebear API
  String _getBadgeImageUrl(String badgeId) {
    // Using Dicebear's shapes style for badge-like images
    final style = 'shapes';
    final seed = 'eyeconnect-$badgeId';
    return 'https://api.dicebear.com/7.x/$style/svg?seed=$seed&backgroundColor=b6e3f4';
  }

  // Initialize predefined badges in Firestore
  Future<void> initializePredefinedBadges() async {
    final badgesRef = _firestore.collection('badges');

    final predefinedBadges = [
      Badge(
        id: 'helper_10',
        name: 'Helpful Friend',
        description: 'Helped 10 people',
        imageUrl: _getBadgeImageUrl('helper_10'),
        requiredHelps: 10,
      ),
      Badge(
        id: 'helper_50',
        name: 'Super Helper',
        description: 'Helped 50 people',
        imageUrl: _getBadgeImageUrl('helper_50'),
        requiredHelps: 50,
      ),
      Badge(
        id: 'helper_100',
        name: 'Helper Hero',
        description: 'Helped 100 people',
        imageUrl: _getBadgeImageUrl('helper_100'),
        requiredHelps: 100,
      ),
      Badge(
        id: 'time_master',
        name: 'Time Master',
        description: 'Helped for more than 100 minutes',
        imageUrl: _getBadgeImageUrl('time_master'),
        requiredHelps: 0,
      ),
    ];

    for (final badge in predefinedBadges) {
      await badgesRef.doc(badge.id).set(badge.toJson());
    }
  }

  // Get badge image data
  Future<List<int>?> getBadgeImageData(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching badge image',
          error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  // Get all badges
  Future<List<Badge>> getAllBadges() async {
    final snapshot = await _firestore.collection('badges').get();
    return snapshot.docs.map((doc) => Badge.fromJson(doc.data())).toList();
  }

  // Get user badges
  Future<List<Badge>> getUserBadges(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final List<String> badgeIds =
        List<String>.from(userDoc.data()?['badges'] ?? []);

    if (badgeIds.isEmpty) return [];

    final badgesSnapshot = await _firestore
        .collection('badges')
        .where(FieldPath.documentId, whereIn: badgeIds)
        .get();

    return badgesSnapshot.docs
        .map((doc) => Badge.fromJson(doc.data()))
        .toList();
  }

  // Award badge to user
  Future<void> awardBadge(String userId, String badgeId) async {
    await _firestore.collection('users').doc(userId).update({
      'badges': FieldValue.arrayUnion([badgeId])
    });
  }

  // Check and award badges based on help count
  Future<List<Badge>> checkAndAwardBadges(String userId, int helpCount) async {
    final badges = await getAllBadges();
    final userBadges = await getUserBadges(userId);
    final newBadges = <Badge>[];

    for (final badge in badges) {
      if (badge.requiredHelps > 0 &&
          helpCount >= badge.requiredHelps &&
          !userBadges.any((b) => b.id == badge.id)) {
        await awardBadge(userId, badge.id);
        newBadges.add(badge);
      }
    }

    return newBadges;
  }
}
