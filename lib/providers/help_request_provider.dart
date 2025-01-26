import 'package:flutter/foundation.dart';
import '../models/help_request_model.dart';

class HelpRequestProvider extends ChangeNotifier {
  final List<HelpRequest> _requests = [];
  final bool _isLoading = false;
  String? _error;

  List<HelpRequest> get requests => List.unmodifiable(_requests);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void addRequest(HelpRequest request) {
    try {
      _error = null;
      _requests.add(request);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add request: ${e.toString()}';
      notifyListeners();
    }
  }

  void acceptRequest(String id, String volunteerId) {
    try {
      _error = null;
      final index = _requests.indexWhere((req) => req.id == id);
      if (index == -1) {
        throw Exception('Request not found');
      }

      final request = _requests[index];
      if (request.isAccepted) {
        throw Exception('Request already accepted');
      }

      _requests[index] = HelpRequest(
        id: request.id,
        requesterName: request.requesterName,
        requesterId: request.requesterId,
        description: request.description,
        timestamp: request.timestamp,
        isAccepted: true,
        volunteerId: volunteerId,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to accept request: ${e.toString()}';
      notifyListeners();
    }
  }

  void removeRequest(String id) {
    try {
      _error = null;
      final initialLength = _requests.length;
      _requests.removeWhere((req) => req.id == id);
      if (_requests.length == initialLength) {
        throw Exception('Request not found');
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove request: ${e.toString()}';
      notifyListeners();
    }
  }

  List<HelpRequest> getRequestsByUser(String userId) {
    return _requests.where((req) => req.requesterId == userId).toList();
  }

  List<HelpRequest> getAcceptedRequestsByVolunteer(String volunteerId) {
    return _requests
        .where((req) => req.isAccepted && req.volunteerId == volunteerId)
        .toList();
  }
}
