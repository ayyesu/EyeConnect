class HelpRequest {
  final String id;
  final String requesterName;
  bool isAccepted;
  String? volunteerId;  // Add this field

  HelpRequest({
    required this.id,
    required this.requesterName,
    this.isAccepted = false,
    this.volunteerId,
  });
}
