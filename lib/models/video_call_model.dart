class VideoCallModel {
  final String sessionId;
  final String volunteerId; // ID of the volunteer
  final String visuallyImpairedUserId; // ID of the visually impaired user
  final String channelName;
  final DateTime startedAt;
  final DateTime? endedAt;

  VideoCallModel({
    required this.sessionId,
    required this.volunteerId,
    required this.visuallyImpairedUserId,
    required this.channelName,
    required this.startedAt,
    this.endedAt,
  });

  // Factory constructor to create VideoCallModel from JSON
  factory VideoCallModel.fromJson(Map<String, dynamic> json) {
    return VideoCallModel(
      sessionId: json['sessionId'],
      volunteerId: json['volunteerId'],
      visuallyImpairedUserId: json['visuallyImpairedUserId'],
      channelName: json['channelName'],
      startedAt: DateTime.parse(json['startedAt']),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
    );
  }

  // Method to convert VideoCallModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'volunteerId': volunteerId,
      'visuallyImpairedUserId': visuallyImpairedUserId,
      'channelName': channelName,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }
}
