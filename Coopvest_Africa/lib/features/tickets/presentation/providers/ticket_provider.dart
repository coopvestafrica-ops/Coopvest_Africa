import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/models.dart';
import '../../data/services/ticket_service.dart';
import '../../../../core/notifications/notification_service.dart';

enum TicketFilter { all, open, inProgress, resolved, closed, cancelled }

enum TicketSort { newest, oldest, priority, status, category }

class TicketProvider with ChangeNotifier {
  final TicketService _ticketService;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;
  StreamSubscription? _ticketsSubscription;

  TicketProvider({
    TicketService? ticketService,
    FirebaseAuth? auth,
    NotificationService? notificationService,
  })  : _ticketService = ticketService ?? TicketService(),
        _auth = auth ?? FirebaseAuth.instance,
        _notificationService = notificationService ?? NotificationService();

  List<TicketModel> _tickets = [];
  TicketModel? _selectedTicket;
  bool _isLoading = false;
  String? _error;
  TicketFilter _currentFilter = TicketFilter.all;
  TicketSort _currentSort = TicketSort.newest;

  // Getters
  List<TicketModel> get tickets => _filterAndSortTickets();
  TicketModel? get selectedTicket => _selectedTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TicketFilter get currentFilter => _currentFilter;
  TicketSort get currentSort => _currentSort;

  // Initialize and load tickets
  Future<void> initialize() async {
    await loadUserTickets();
  }

  Future<void> loadUserTickets() async {
    try {
      _setLoading(true);
      _clearError();

      // Cancel existing subscription if any
      await _ticketsSubscription?.cancel();

      // Subscribe to ticket updates
      _ticketsSubscription = _ticketService.getUserTickets().listen(
        (tickets) {
          // Check for updates in each ticket
          for (var newTicket in tickets) {
            var oldTicket = _tickets.firstWhere(
              (t) => t.id == newTicket.id,
              orElse: () => newTicket,
            );

            if (oldTicket != newTicket) {
              _handleTicketUpdate(newTicket);
            }
          }

          _tickets = tickets;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError(error.toString());
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Create new ticket
  Future<void> createTicket({
    required String subject,
    required String description,
    required TicketPriority priority,
    required TicketCategory category,
    List<String>? attachments,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final ticket = await _ticketService.createTicket(
        subject: subject,
        description: description,
        priority: priority,
      );

      // Send notification for ticket creation
      await _notificationService.showNotification(
        title: 'Ticket Created',
        body: 'Your ticket #${ticket.id} has been created successfully',
        payload: 'ticket:${ticket.id}',
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Select and load ticket details
  Future<void> selectTicket(String ticketId) async {
    try {
      _clearError();
      _selectedTicket = null;
      notifyListeners();

      final ticketStream = _ticketService.getTicketById(ticketId);
      await for (final ticket in ticketStream) {
        _selectedTicket = ticket;
        notifyListeners();
        break; // Get first emission only
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Update ticket status
  Future<void> updateTicketStatus(
      String ticketId, TicketStatus newStatus) async {
    try {
      _clearError();
      await _ticketService.updateTicketStatus(ticketId, newStatus);

      // Send notification for status update
      String statusMessage = '';
      switch (newStatus) {
        case TicketStatus.inProgress:
          statusMessage = 'Your ticket is now being processed';
          break;
        case TicketStatus.resolved:
          statusMessage = 'Your ticket has been resolved';
          break;
        case TicketStatus.closed:
          statusMessage = 'Your ticket has been closed';
          break;
        case TicketStatus.cancelled:
          statusMessage = 'Your ticket has been cancelled';
          break;
        default:
          statusMessage = 'Your ticket status has been updated';
      }

      await _notificationService.showNotification(
        title: 'Ticket Status Updated',
        body: statusMessage,
        payload: 'ticket:$ticketId',
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Add response to ticket
  Future<void> addResponse({
    required String ticketId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _ticketService.addResponse(
        ticketId,
        message,
        attachments: attachments,
      );

      // Get ticket details for the notification
      final ticket = await _ticketService.getTicketById(ticketId).first;

      // Send notification for new response
      await _notificationService.showNotification(
        title: 'New Response',
        body: 'New response added to ticket: ${ticket.subject}',
        payload: 'ticket:$ticketId',
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  List<TicketModel> _filterAndSortTickets() {
    // Apply filter
    var filteredTickets = _tickets.where((ticket) {
      switch (_currentFilter) {
        case TicketFilter.all:
          return true;
        case TicketFilter.open:
          return ticket.isOpen;
        case TicketFilter.inProgress:
          return ticket.isInProgress;
        case TicketFilter.resolved:
          return ticket.isResolved;
        case TicketFilter.closed:
          return ticket.isClosed;
        case TicketFilter.cancelled:
          return ticket.isCancelled;
      }
    }).toList();

    // Apply sort
    filteredTickets.sort((a, b) {
      switch (_currentSort) {
        case TicketSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case TicketSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case TicketSort.priority:
          return b.priority.index.compareTo(a.priority.index);
        case TicketSort.status:
          return a.status.index.compareTo(b.status.index);
        case TicketSort.category:
          return a.category.index.compareTo(b.category.index);
      }
    });

    return filteredTickets;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Filter and sort methods
  void setFilter(TicketFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setSort(TicketSort sort) {
    _currentSort = sort;
    notifyListeners();
  }

  // Clear selected ticket
  void clearSelectedTicket() {
    _selectedTicket = null;
    notifyListeners();
  }

  // Analytics and monitoring
  int get totalTickets => _tickets.length;
  int get openTickets => _tickets.where((t) => t.isOpen).length;
  int get resolvedTickets => _tickets.where((t) => t.isResolved).length;
  double get resolutionRate =>
      _tickets.isEmpty ? 0 : (resolvedTickets / totalTickets) * 100;

  Duration? get averageResolutionTime {
    final resolvedList = _tickets.where((t) => t.timeToResolution != null);
    if (resolvedList.isEmpty) return null;

    final totalDuration = resolvedList.fold<Duration>(
      Duration.zero,
      (sum, ticket) => sum + (ticket.timeToResolution ?? Duration.zero),
    );
    return Duration(
      milliseconds: totalDuration.inMilliseconds ~/ resolvedList.length,
    );
  }

  // Handle ticket updates and send notifications
  void _handleTicketUpdate(TicketModel updatedTicket) {
    final existingTicket = _tickets.firstWhere(
      (t) => t.id == updatedTicket.id,
      orElse: () => updatedTicket,
    );

    // Check if this is a status change
    if (existingTicket.status != updatedTicket.status) {
      _notifyTicketStatusChange(updatedTicket);
    }

    // Check if there are new responses
    if (existingTicket.responseCount < updatedTicket.responseCount) {
      _notifyNewResponse(updatedTicket);
    }
  }

  // Notify status change
  Future<void> _notifyTicketStatusChange(TicketModel ticket) async {
    String message =
        'Ticket status changed to ${ticket.status.toString().split('.').last}';
    await _notificationService.showNotification(
      title: 'Ticket Status Update',
      body: message,
      payload: 'ticket:${ticket.id}',
    );
  }

  // Notify new response
  Future<void> _notifyNewResponse(TicketModel ticket) async {
    final latestResponse = ticket.lastResponse;
    if (latestResponse != null) {
      await _notificationService.showNotification(
        title: 'New Response',
        body: 'New response added to ticket: ${ticket.subject}',
        payload: 'ticket:${ticket.id}',
      );
    }
  }

  @override
  void dispose() {
    _ticketsSubscription?.cancel();
    super.dispose();
  }
}
