import 'package:flutter/foundation.dart';
import '../models/help_request_model.dart';

class HelpRequestProvider extends ChangeNotifier {
  final List<HelpRequest> _requests = [];

  List<HelpRequest> get requests => _requests;

  void addRequest(HelpRequest request) {
    _requests.add(request);
    notifyListeners();
  }

  void acceptRequest(String id, String volunteerId) {  // Updated method
    final request = _requests.firstWhere((req) => req.id == id);
    request.isAccepted = true;
    request.volunteerId = volunteerId;  // Add volunteer ID
    notifyListeners();
  }

  void removeRequest(String id) {
    _requests.removeWhere((req) => req.id == id);
    notifyListeners();
  }
}