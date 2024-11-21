class HelpRequestModel {
  final String requestId;
  final String userId; // ID of the user who requested help
  final String description;
  final DateTime createdAt;
  final bool isResolved;

  HelpRequestModel({
    required this.requestId,
    required this.userId,
    required this.description,
    required this.createdAt,
    this.isResolved = false,
  });

  // Factory constructor to create a HelpRequestModel from JSON
  factory HelpRequestModel.fromJson(Map<String, dynamic> json) {
    return HelpRequestModel(
      requestId: json['requestId'],
      userId: json['userId'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      isResolved: json['isResolved'] ?? false,
    );
  }

  // Method to convert HelpRequestModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'userId': userId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved,
    };
  }
}
