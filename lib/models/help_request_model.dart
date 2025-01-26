class HelpRequest {
  final String id;
  final String requesterName;
  final String requesterId;
  final String description;
  final DateTime timestamp;
  bool isAccepted;
  String? volunteerId;

  HelpRequest({
    required this.id,
    required this.requesterName,
    required this.requesterId,
    required this.description,
    required this.timestamp,
    this.isAccepted = false,
    this.volunteerId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterName': requesterName,
    'requesterId': requesterId,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'isAccepted': isAccepted,
    'volunteerId': volunteerId,
  };

  factory HelpRequest.fromJson(Map<String, dynamic> json) => HelpRequest(
    id: json['id'],
    requesterName: json['requesterName'],
    requesterId: json['requesterId'],
    description: json['description'],
    timestamp: DateTime.parse(json['timestamp']),
    isAccepted: json['isAccepted'] ?? false,
    volunteerId: json['volunteerId'],
  );
}
