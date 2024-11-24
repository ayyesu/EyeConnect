class HelpRequest {
  final String id; // Unique identifier for the request
  final String requesterName; // Name of the visually impaired person
  bool isAccepted; // Status of the request

  HelpRequest({
    required this.id,
    required this.requesterName,
    this.isAccepted = false,
  });
}
