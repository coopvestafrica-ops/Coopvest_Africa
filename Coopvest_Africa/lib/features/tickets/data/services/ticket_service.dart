import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ticket_model.dart';
import '../models/ticket_response.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _ticketsCollection =>
      _firestore.collection('tickets');
  CollectionReference get _responsesCollection =>
      _firestore.collection('ticket_responses');

  // Create a new ticket
  Future<TicketModel> createTicket({
    required String subject,
    required String description,
    required TicketPriority priority,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _ticketsCollection.doc();
    final now = DateTime.now();

    final ticket = TicketModel(
      id: docRef.id,
      userId: user.uid,
      userEmail: user.email ?? '',  // Add user's email from FirebaseAuth
      subject: subject,
      description: description,
      status: TicketStatus.open,
      priority: priority,
      createdAt: now,
      responses: [],
    );

    await docRef.set(ticket.toJson());
    return ticket;
  }

  // Get all tickets for the current user
  Stream<List<TicketModel>> getUserTickets() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _ticketsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TicketModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get a specific ticket by ID
  Stream<TicketModel> getTicketById(String ticketId) {
    return _ticketsCollection
        .doc(ticketId)
        .snapshots()
        .map((doc) => TicketModel.fromJson(doc.data() as Map<String, dynamic>));
  }

  // Update ticket status
  Future<void> updateTicketStatus(
      String ticketId, TicketStatus newStatus) async {
    await _ticketsCollection.doc(ticketId).update({
      'status': newStatus.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add a response to a ticket
  Future<void> addResponse(String ticketId, String message,
      {List<String>? attachments}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _responsesCollection.doc();
    final response = TicketResponse(
      id: docRef.id,
      ticketId: ticketId,
      userId: user.uid,
      message: message,
      isStaff: false, // Set based on user role
      createdAt: DateTime.now(),
      attachments: attachments,
    );

    await docRef.set(response.toJson());
    await _ticketsCollection.doc(ticketId).update({
      'updatedAt': FieldValue.serverTimestamp(),
      'responses': FieldValue.arrayUnion([response.toJson()]),
    });
  }

  // Get all responses for a ticket
  Stream<List<TicketResponse>> getTicketResponses(String ticketId) {
    return _responsesCollection
        .where('ticketId', isEqualTo: ticketId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TicketResponse.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Delete a ticket (optional, may want to keep for record)
  Future<void> deleteTicket(String ticketId) async {
    final batch = _firestore.batch();

    // Delete the ticket
    batch.delete(_ticketsCollection.doc(ticketId));

    // Delete all responses for the ticket
    final responses =
        await _responsesCollection.where('ticketId', isEqualTo: ticketId).get();

    for (var response in responses.docs) {
      batch.delete(response.reference);
    }

    await batch.commit();
  }
}
