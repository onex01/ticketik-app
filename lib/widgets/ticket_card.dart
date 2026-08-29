import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../core/constants.dart';

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;
  final VoidCallback onStatusChange;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
    required this.onStatusChange,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case RequestStatus.newRequest:
        return Colors.orange;
      case RequestStatus.inProgress:
        return Colors.blue;
      case RequestStatus.done:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case RequestStatus.newRequest:
        return 'Новая';
      case RequestStatus.inProgress:
        return 'В работе';
      case RequestStatus.done:
        return 'Выполнено';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(ticket.status),
                      style: TextStyle(
                        color: _getStatusColor(ticket.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Каб. ${ticket.room}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.computer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(ticket.pcNumber, style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: onStatusChange,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}