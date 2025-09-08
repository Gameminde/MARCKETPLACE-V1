import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../models/support_ticket.dart';
import '../services/support_ticket_service.dart';
import '../widgets/glassmorphic_container.dart';

/// Support ticket system screen
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    SupportTicketService.instance.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Tickets', icon: Icon(Icons.support_agent)),
            Tab(text: 'FAQ', icon: Icon(Icons.help)),
          ],
        ),
      ),
      body: Consumer<SupportTicketService>(
        builder: (context, supportService, child) {
          if (!supportService.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTicketsTab(supportService),
              _buildFAQTab(supportService),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTicket,
        label: const Text('New Ticket'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTicketsTab(SupportTicketService supportService) {
    final tickets = supportService.tickets;

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'No support tickets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton.icon(
              onPressed: _createNewTicket,
              icon: const Icon(Icons.add),
              label: const Text('Create Ticket'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: TicketCard(
            ticket: ticket,
            onTap: () => _openTicketDetails(ticket),
          ),
        );
      },
    );
  }

  Widget _buildFAQTab(SupportTicketService supportService) {
    final faqs = supportService.faqs;

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: FAQCard(faq: faq),
        );
      },
    );
  }

  void _createNewTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTicketScreen(),
      ),
    );
  }

  void _openTicketDetails(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailsScreen(ticket: ticket),
      ),
    );
  }
}

/// Ticket card widget
class TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer.card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.spacingM),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ticket.priority.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(ticket.category.icon, color: ticket.priority.color),
        ),
        title: Text(
          ticket.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ticket.status.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(ticket.timeAgo),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

/// FAQ card widget
class FAQCard extends StatefulWidget {
  final FAQ faq;

  const FAQCard({super.key, required this.faq});

  @override
  State<FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<FAQCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer.card(
      child: ExpansionTile(
        leading: Icon(widget.faq.category.icon, color: Theme.of(context).colorScheme.primary),
        title: Text(widget.faq.question),
        onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.faq.answer),
                const SizedBox(height: AppConstants.spacingM),
                Row(
                  children: [
                    const Text('Was this helpful?'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _markHelpful(true),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text('Yes'),
                    ),
                    TextButton.icon(
                      onPressed: () => _markHelpful(false),
                      icon: const Icon(Icons.thumb_down, size: 16),
                      label: const Text('No'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _markHelpful(bool isHelpful) {
    SupportTicketService.instance.markFAQHelpful(widget.faq.id, isHelpful);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isHelpful ? 'Thank you!' : 'We\'ll improve this')),
    );
  }
}

/// Create ticket screen
class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TicketCategory _selectedCategory = TicketCategory.general;
  TicketPriority _selectedPriority = TicketPriority.normal;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Support Ticket'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitTicket,
            child: _isSubmitting 
                ? const CircularProgressIndicator()
                : const Text('Submit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Enter a title' : null,
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => value?.isEmpty == true ? 'Enter a description' : null,
              ),
              const SizedBox(height: AppConstants.spacingM),
              DropdownButtonFormField<TicketCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: TicketCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: AppConstants.spacingM),
              DropdownButtonFormField<TicketPriority>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: TicketPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: priority.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(priority.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPriority = value!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final ticket = await SupportTicketService.instance.createTicket(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
    );

    if (ticket != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket #${ticket.id} created!')),
      );
    }

    if (mounted) setState(() => _isSubmitting = false);
  }
}

/// Ticket details screen
class TicketDetailsScreen extends StatelessWidget {
  final SupportTicket ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${ticket.id}'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ticket.status.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ticket.status.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    Text('Created ${ticket.timeAgo}'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              itemCount: ticket.messages.length,
              itemBuilder: (context, index) {
                final message = ticket.messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                  child: Row(
                    mainAxisAlignment: message.isFromAgent
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end,
                    children: [
                      if (!message.isFromAgent) const Spacer(),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(AppConstants.spacingM),
                          decoration: BoxDecoration(
                            color: message.isFromAgent
                                ? Theme.of(context).colorScheme.surfaceVariant
                                : Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.isFromAgent) ...[
                                Text(
                                  message.senderName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: message.isFromAgent
                                      ? Theme.of(context).colorScheme.onSurfaceVariant
                                      : Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.timeAgo,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: message.isFromAgent
                                      ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)
                                      : Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (message.isFromAgent) const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}