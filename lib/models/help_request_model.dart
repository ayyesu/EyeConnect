class HelpRequest {
  final String id;
  final String requesterName;
  final String requesterId;
  final String description;
  final DateTime timestamp;
  final bool isAccepted;
  final String? volunteerId;
  final bool roomCreated;
  final String status;

  HelpRequest({
    required this.id,
    required this.requesterName,
    required this.requesterId,
    required this.description,
    required this.timestamp,
    this.isAccepted = false,
    this.volunteerId,
    this.roomCreated = false,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterName': requesterName,
    'requesterId': requesterId,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'isAccepted': isAccepted,
    'volunteerId': volunteerId,
    'roomCreated': roomCreated,
    'status': status,
  };

  factory HelpRequest.fromJson(Map<String, dynamic> json) => HelpRequest(
    id: json['id'],
    requesterName: json['requesterName'],
    requesterId: json['requesterId'],
    description: json['description'],
    timestamp: DateTime.parse(json['timestamp']),
    isAccepted: json['isAccepted'] ?? false,
    volunteerId: json['volunteerId'],
    roomCreated: json['roomCreated'] ?? false,
    status: json['status'] ?? 'pending',
  );
}
