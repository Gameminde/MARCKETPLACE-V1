import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/support_ticket.dart';
import '../services/notification_service.dart';
import '../core/config/app_constants.dart';

/// Support ticket service for managing customer service tickets
class SupportTicketService extends ChangeNotifier {
  static SupportTicketService? _instance;
  static SupportTicketService get instance => _instance ??= SupportTicketService._internal();
  
  SupportTicketService._internal();

  // Dependencies
  SharedPreferences? _prefs;

  // State
  final List<SupportTicket> _tickets = [];
  final List<FAQ> _faqs = [];
  final List<SupportAgent> _agents = [];
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SupportTicket> get tickets => List.unmodifiable(_tickets);
  List<FAQ> get faqs => List.unmodifiable(_faqs);
  List<SupportAgent> get agents => List.unmodifiable(_agents);

  List<SupportTicket> get openTickets => 
      _tickets.where((ticket) => ticket.isOpen).toList();

  List<SupportTicket> get resolvedTickets => 
      _tickets.where((ticket) => ticket.isResolved).toList();

  int get openTicketCount => openTickets.length;

  /// Initialize support ticket service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      
      _prefs = await SharedPreferences.getInstance();
      
      // Load cached data
      await _loadCachedData();
      
      // Load initial data
      await _loadTickets();
      await _loadFAQs();
      await _loadAgents();
      
      _isInitialized = true;
      debugPrint('SupportTicketService initialized successfully');
      
    } catch (e) {
      debugPrint('Failed to initialize SupportTicketService: $e');
      _setError('Failed to initialize support service');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new support ticket
  Future<SupportTicket?> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    TicketPriority priority = TicketPriority.normal,
    List<String> attachmentUrls = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _setLoading(true);

      final ticket = SupportTicket(
        id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user', // In real app, get from auth
        title: title,
        description: description,
        category: category,
        priority: priority,
        status: TicketStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attachmentUrls: attachmentUrls,
        metadata: metadata,
        messages: [
          TicketMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            ticketId: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
            senderId: 'current_user',
            senderName: 'You',
            content: description,
            isFromAgent: false,
            timestamp: DateTime.now(),
            attachmentUrls: attachmentUrls,
          ),
        ],
      );

      // Add to tickets list
      _tickets.insert(0, ticket);
      
      // Auto-assign agent based on category
      final assignedTicket = await _autoAssignAgent(ticket);
      if (assignedTicket != null) {
        final index = _tickets.indexWhere((t) => t.id == ticket.id);
        if (index != -1) {
          _tickets[index] = assignedTicket;
        }
      }

      await _cacheTickets();
      notifyListeners();

      // Send confirmation notification
      await NotificationService.instance.addNotification(
        NotificationService.createSystemNotification(
          title: 'Support Ticket Created',
          message: 'Your support ticket #${ticket.id} has been created successfully.',
        ),
      );

      return assignedTicket ?? ticket;
    } catch (e) {
      debugPrint('Error creating support ticket: $e');
      _setError('Failed to create support ticket');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Add message to ticket
  Future<bool> addMessageToTicket({
    required String ticketId,
    required String content,
    List<String> attachmentUrls = const [],
  }) async {
    try {
      final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
      if (ticketIndex == -1) return false;

      final message = TicketMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        ticketId: ticketId,
        senderId: 'current_user',
        senderName: 'You',
        content: content,
        isFromAgent: false,
        timestamp: DateTime.now(),
        attachmentUrls: attachmentUrls,
      );

      final updatedMessages = List<TicketMessage>.from(_tickets[ticketIndex].messages);
      updatedMessages.add(message);

      _tickets[ticketIndex] = _tickets[ticketIndex].copyWith(
        messages: updatedMessages,
        status: TicketStatus.waitingForResponse,
        updatedAt: DateTime.now(),
      );

      await _cacheTickets();
      notifyListeners();

      // Simulate agent response after a delay
      _simulateAgentResponse(ticketId);

      return true;
    } catch (e) {
      debugPrint('Error adding message to ticket: $e');
      return false;
    }
  }

  /// Update ticket status
  Future<bool> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
      if (ticketIndex == -1) return false;

      _tickets[ticketIndex] = _tickets[ticketIndex].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      await _cacheTickets();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating ticket status: $e');
      return false;
    }
  }

  /// Close ticket
  Future<bool> closeTicket(String ticketId) async {
    return await updateTicketStatus(ticketId, TicketStatus.closed);
  }

  /// Reopen ticket
  Future<bool> reopenTicket(String ticketId) async {
    return await updateTicketStatus(ticketId, TicketStatus.open);
  }

  /// Get ticket by ID
  SupportTicket? getTicketById(String ticketId) {
    try {
      return _tickets.firstWhere((ticket) => ticket.id == ticketId);
    } catch (e) {
      return null;
    }
  }

  /// Get tickets by category
  List<SupportTicket> getTicketsByCategory(TicketCategory category) {
    return _tickets.where((ticket) => ticket.category == category).toList();
  }

  /// Get tickets by status
  List<SupportTicket> getTicketsByStatus(TicketStatus status) {
    return _tickets.where((ticket) => ticket.status == status).toList();
  }

  /// Search tickets
  List<SupportTicket> searchTickets(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _tickets.where((ticket) =>
      ticket.title.toLowerCase().contains(lowercaseQuery) ||
      ticket.description.toLowerCase().contains(lowercaseQuery) ||
      ticket.id.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Search FAQs
  List<FAQ> searchFAQs(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _faqs.where((faq) =>
      faq.question.toLowerCase().contains(lowercaseQuery) ||
      faq.answer.toLowerCase().contains(lowercaseQuery) ||
      faq.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  /// Get FAQs by category
  List<FAQ> getFAQsByCategory(TicketCategory category) {
    return _faqs.where((faq) => faq.category == category).toList();
  }

  /// Mark FAQ as helpful
  Future<void> markFAQHelpful(String faqId, bool isHelpful) async {
    try {
      final faqIndex = _faqs.indexWhere((faq) => faq.id == faqId);
      if (faqIndex != -1) {
        // In a real app, this would update the server
        debugPrint('Marked FAQ $faqId as ${isHelpful ? 'helpful' : 'not helpful'}');
      }
    } catch (e) {
      debugPrint('Error marking FAQ as helpful: $e');
    }
  }

  /// Get available agents for category
  List<SupportAgent> getAgentsForCategory(TicketCategory category) {
    return _agents.where((agent) => 
      agent.specialties.contains(category) || agent.specialties.isEmpty
    ).toList();
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Auto-assign agent to ticket
  Future<SupportTicket?> _autoAssignAgent(SupportTicket ticket) async {
    try {
      final availableAgents = getAgentsForCategory(ticket.category);
      
      if (availableAgents.isNotEmpty) {
        // For now, assign to the first available agent
        // In a real app, this would use load balancing logic
        final agent = availableAgents.first;
        
        return ticket.copyWith(
          assignedAgentId: agent.id,
          assignedAgentName: agent.name,
          status: TicketStatus.inProgress,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error auto-assigning agent: $e');
      return null;
    }
  }

  /// Simulate agent response
  void _simulateAgentResponse(String ticketId) {
    // Simulate a delay for agent response
    Timer(const Duration(minutes: 2), () async {
      final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
      if (ticketIndex == -1) return;

      final ticket = _tickets[ticketIndex];
      if (ticket.assignedAgentName == null) return;

      final responseMessage = TicketMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        ticketId: ticketId,
        senderId: ticket.assignedAgentId!,
        senderName: ticket.assignedAgentName!,
        content: 'Thank you for your message. I\'m looking into this issue and will get back to you shortly with an update.',
        isFromAgent: true,
        timestamp: DateTime.now(),
      );

      final updatedMessages = List<TicketMessage>.from(ticket.messages);
      updatedMessages.add(responseMessage);

      _tickets[ticketIndex] = ticket.copyWith(
        messages: updatedMessages,
        status: TicketStatus.inProgress,
        updatedAt: DateTime.now(),
      );

      await _cacheTickets();
      notifyListeners();

      // Send notification about agent response
      await NotificationService.instance.addNotification(
        NotificationService.createSystemNotification(
          title: 'Support Agent Responded',
          message: '${ticket.assignedAgentName} responded to your ticket #${ticket.id}',
        ),
      );
    });
  }

  /// Load tickets
  Future<void> _loadTickets() async {
    try {
      // In a real app, this would fetch from API
      // For now, load mock data if none cached
      if (_tickets.isEmpty) {
        final mockTickets = SupportTicket.mockTickets();
        _tickets.addAll(mockTickets);
        await _cacheTickets();
      }
    } catch (e) {
      debugPrint('Error loading tickets: $e');
    }
  }

  /// Load FAQs
  Future<void> _loadFAQs() async {
    try {
      // In a real app, this would fetch from API
      final mockFAQs = FAQ.mockFAQs();
      _faqs.addAll(mockFAQs);
    } catch (e) {
      debugPrint('Error loading FAQs: $e');
    }
  }

  /// Load agents
  Future<void> _loadAgents() async {
    try {
      // Mock agent data
      _agents.addAll([
        const SupportAgent(
          id: 'agent_1',
          name: 'Sarah Johnson',
          email: 'sarah.johnson@marketplace.com',
          department: 'Customer Service',
          isOnline: true,
          specialties: [TicketCategory.shipping, TicketCategory.order],
          rating: 4.8,
          ticketsResolved: 1250,
        ),
        const SupportAgent(
          id: 'agent_2',
          name: 'Mike Chen',
          email: 'mike.chen@marketplace.com',
          department: 'Customer Service',
          isOnline: true,
          specialties: [TicketCategory.refund, TicketCategory.product],
          rating: 4.9,
          ticketsResolved: 980,
        ),
        const SupportAgent(
          id: 'agent_3',
          name: 'Lisa Wang',
          email: 'lisa.wang@marketplace.com',
          department: 'Technical Support',
          isOnline: false,
          specialties: [TicketCategory.technical, TicketCategory.account],
          rating: 4.7,
          ticketsResolved: 756,
        ),
      ]);
    } catch (e) {
      debugPrint('Error loading agents: $e');
    }
  }

  /// Load cached data
  Future<void> _loadCachedData() async {
    try {
      // Load cached tickets
      final ticketsJson = _prefs?.getString('support_tickets');
      if (ticketsJson != null) {
        final List<dynamic> ticketsList = jsonDecode(ticketsJson);
        _tickets.clear();
        _tickets.addAll(
          ticketsList.map((data) => SupportTicket.fromJson(data))
        );
      }
    } catch (e) {
      debugPrint('Error loading cached support data: $e');
    }
  }

  /// Cache tickets
  Future<void> _cacheTickets() async {
    try {
      final ticketsList = _tickets.map((t) => t.toJson()).toList();
      await _prefs?.setString('support_tickets', jsonEncode(ticketsList));
    } catch (e) {
      debugPrint('Error caching support tickets: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
}