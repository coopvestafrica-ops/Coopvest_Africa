import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../providers/ticket_provider.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isAttaching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().selectTicket(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAttachmentOptions() {
    setState(() => _isAttaching = true);
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement image picker
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Photo'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement camera capture
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('Attach Document'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement file picker
            },
          ),
        ],
      ),
    ).then((_) => setState(() => _isAttaching = false));
  }

  Future<void> _sendResponse() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await context.read<TicketProvider>().addResponse(
            ticketId: widget.ticketId,
            message: message,
          );
      _messageController.clear();

      // Scroll to bottom after message is sent
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
        actions: [
          PopupMenuButton<TicketStatus>(
            onSelected: (status) {
              context
                  .read<TicketProvider>()
                  .updateTicketStatus(widget.ticketId, status);
            },
            itemBuilder: (context) {
              return TicketStatus.values.map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Text(status.toString().split('.').last),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Consumer<TicketProvider>(
        builder: (context, provider, child) {
          final ticket = provider.selectedTicket;

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.selectTicket(widget.ticketId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (ticket == null) {
            return const Center(child: Text('Ticket not found'));
          }

          return Column(
            children: [
              // Ticket details
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(ticket.description),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(ticket.status),
                        const SizedBox(width: 8),
                        _buildPriorityChip(ticket.priority),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Responses
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: ticket.responses.length,
                  itemBuilder: (context, index) {
                    return _ResponseBubble(response: ticket.responses[index]);
                  },
                ),
              ),
              // Message input
              if (ticket.status != TicketStatus.closed)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showAttachmentOptions,
                        icon: Icon(
                          Icons.attach_file,
                          color: _isAttaching
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).iconTheme.color,
                        ),
                      ),
                      IconButton(
                        onPressed: _sendResponse,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    Color color;
    switch (status) {
      case TicketStatus.open:
        color = Colors.blue;
        break;
      case TicketStatus.inProgress:
        color = Colors.orange;
        break;
      case TicketStatus.resolved:
        color = Colors.green;
        break;
      case TicketStatus.closed:
        color = Colors.grey;
        break;
      case TicketStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        status.toString().split('.').last,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildPriorityChip(TicketPriority priority) {
    Color color;
    switch (priority) {
      case TicketPriority.low:
        color = Colors.green;
        break;
      case TicketPriority.medium:
        color = Colors.orange;
        break;
      case TicketPriority.high:
        color = Colors.red;
        break;
      case TicketPriority.urgent:
        color = Colors.purple;
        break;
    }

    return Chip(
      label: Text(
        priority.toString().split('.').last,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}

class _ResponseBubble extends StatelessWidget {
  final TicketResponse response;

  const _ResponseBubble({required this.response});

  @override
  Widget build(BuildContext context) {
    final isStaff = response.isStaff;

    return Align(
      alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isStaff
              ? Colors.grey[300]
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(response.message),
            const SizedBox(height: 4),
            Text(
              _formatDate(response.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (response.attachments != null &&
                response.attachments!.isNotEmpty)
              Column(
                crossAxisAlignment:
                    isStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: response.attachments!.map((url) {
                  return InkWell(
                    onTap: () {
                      // Handle attachment tap
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attachment, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              url.split('/').last,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}/${date.year}';
  }
}
