class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final DateTime sentAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.sentAt,
  });

  // Factory constructor to create NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      sentAt: DateTime.parse(json['sentAt']),
    );
  }

  // Method to convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
    };
  }
}
