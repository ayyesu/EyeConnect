import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/help_request_model.dart';
import 'package:logger/logger.dart';

class HelpRequestProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  List<HelpRequest> _requests = [];
  List<HelpRequest> _acceptedRequests = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _requestSubscription;
  StreamSubscription<QuerySnapshot>? _acceptedRequestSubscription;

  List<HelpRequest> get requests => List.unmodifiable(_requests);
  List<HelpRequest> get acceptedRequests =>
      List.unmodifiable(_acceptedRequests);
  bool get isLoading => _isLoading;
  String? get error => _error;

  HelpRequestProvider() {
    // Initialize real-time listeners
    _initRequestListener();
    _initAcceptedRequestListener();
  }

  void _initRequestListener() {
    try {
      _requestSubscription = _firestore
          .collection('help_requests')
          .where('isAccepted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        final newRequests = snapshot.docs.map((doc) {
          final data = doc.data();
          return HelpRequest(
            id: doc.id,
            requesterName: data['requesterName'] ?? '',
            requesterId: data['requesterId'] ?? '',
            description: data['description'] ?? '',
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            isAccepted: data['isAccepted'] ?? false,
            volunteerId: data['volunteerId'],
            roomCreated: data['roomCreated'] ?? false,
            status: data['status'] ?? '',
          );
        }).toList();

        // Only update and notify if the list has changed
        if (!listEquals(_requests, newRequests)) {
          _requests = newRequests;
          notifyListeners();
        }
      }, onError: (error) {
        _logger.e('Error listening to help requests: $error');
        _error = 'Failed to listen to requests: ${error.toString()}';
        notifyListeners();
      });
    } catch (e) {
      _logger.e('Error setting up help request listener: $e');
      _error = 'Failed to initialize request listener: ${e.toString()}';
      notifyListeners();
    }
  }

  void _initAcceptedRequestListener() {
    try {
      _acceptedRequestSubscription = _firestore
          .collection('help_requests')
          .where('isAccepted', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        final newAcceptedRequests = snapshot.docs.map((doc) {
          final data = doc.data();
          return HelpRequest(
            id: doc.id,
            requesterName: data['requesterName'] ?? '',
            requesterId: data['requesterId'] ?? '',
            description: data['description'] ?? '',
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            isAccepted: data['isAccepted'] ?? false,
            volunteerId: data['volunteerId'],
            roomCreated: data['roomCreated'] ?? false,
            status: data['status'] ?? '',
          );
        }).toList();

        // Only update and notify if the list has changed
        if (!listEquals(_acceptedRequests, newAcceptedRequests)) {
          _acceptedRequests = newAcceptedRequests;
          notifyListeners();
        }
      }, onError: (error) {
        _logger.e('Error listening to accepted requests: $error');
        _error = 'Failed to listen to accepted requests: ${error.toString()}';
        notifyListeners();
      });
    } catch (e) {
      _logger.e('Error setting up accepted request listener: $e');
      _error =
          'Failed to initialize accepted request listener: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> addRequest(HelpRequest request) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('help_requests').doc(request.id).set({
        'requesterName': request.requesterName,
        'requesterId': request.requesterId,
        'description': request.description,
        'timestamp': Timestamp.fromDate(request.timestamp),
        'isAccepted': false,
        'volunteerId': null,
        'roomCreated': false,
        'status': 'pending',
      });

      _logger.i('Help request created successfully with ID: ${request.id}');
    } catch (e) {
      _logger.e('Error adding request: $e');
      _error = 'Failed to add request: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptRequest(String id, String volunteerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // First check if the request is still available
      final requestDoc = await _firestore.collection('help_requests').doc(id).get();
      if (!requestDoc.exists) {
        throw Exception('Help request no longer exists');
      }

      final requestData = requestDoc.data()!;
      if (requestData['isAccepted'] == true) {
        throw Exception('Help request has already been accepted by another volunteer');
      }

      // Update the request status
      await _firestore.collection('help_requests').doc(id).update({
        'isAccepted': true,
        'volunteerId': volunteerId,
        'status': 'accepted',
      });

      _logger.i('Help request accepted successfully');
    } catch (e) {
      _logger.e('Error accepting help request: $e');
      _error = 'Failed to accept request: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeRequest(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('help_requests').doc(id).delete();
      _logger.i('Help request removed successfully');
    } catch (e) {
      _logger.e('Error removing help request: $e');
      _error = 'Failed to remove request: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteHelpRequest(String requestId) async {
    try {
      await _firestore.collection('help_requests').doc(requestId).delete();
      _logger.i('Help request deleted successfully');
    } catch (e) {
      _logger.e('Error deleting help request: $e');
      rethrow;
    }
  }

  Future<void> updateRoomStatus(String requestId, bool roomCreated) async {
    try {
      await _firestore.collection('help_requests').doc(requestId).update({
        'roomCreated': roomCreated,
        'status': roomCreated ? 'in_progress' : 'ended',
      });
      _logger.i('Room status updated successfully');
    } catch (e) {
      _logger.e('Error updating room status: $e');
      _error = 'Failed to update room status: ${e.toString()}';
      rethrow;
    }
  }

  Future<void> updateHelpRequestStatus(String requestId, String status, {String? volunteerId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final Map<String, dynamic> updateData = {
        'status': status,
      };

      if (volunteerId != null) {
        updateData['volunteerId'] = volunteerId;
      }

      await _firestore.collection('help_requests').doc(requestId).update(updateData);
      _logger.i('Help request status updated successfully');
    } catch (e) {
      _logger.e('Error updating help request status: $e');
      _error = 'Failed to update request status: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<HelpRequest> getRequestsByUser(String userId) {
    return [..._requests, ..._acceptedRequests]
        .where((req) => req.requesterId == userId)
        .toList();
  }

  List<HelpRequest> getAcceptedRequestsByVolunteer(String volunteerId) {
    return _acceptedRequests
        .where((req) => req.volunteerId == volunteerId)
        .toList();
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _acceptedRequestSubscription?.cancel();
    super.dispose();
  }
}
