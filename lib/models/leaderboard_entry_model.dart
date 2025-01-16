class LeaderboardEntry {
  final String userId;
  final String userName;
  final int helpCount;
  final double averageRating;
  final Duration totalHelpTime;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.helpCount,
    required this.averageRating,
    required this.totalHelpTime,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'],
      userName: json['userName'],
      helpCount: json['helpCount'],
      averageRating: json['averageRating'].toDouble(),
      totalHelpTime: Duration(minutes: json['totalHelpTimeMinutes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'helpCount': helpCount,
      'averageRating': averageRating,
      'totalHelpTimeMinutes': totalHelpTime.inMinutes,
    };
  }
}
