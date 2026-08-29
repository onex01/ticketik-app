import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';
import '../widgets/ticket_card.dart';
import '../services/firestore_service.dart';
import '../core/constants.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Фильтруем только активные заявки (is_deleted == false)
        // БЕЗ orderBy, чтобы избежать ошибки индексации
        stream: FirebaseFirestore.instance
            .collection(FirestoreCollections.requests)
            .where('is_deleted', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Активных заявок пока нет 🎉',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // Преобразуем документы в модели
          final tickets = snapshot.data!.docs
              .map((doc) => TicketModel.fromFirestore(doc))
              .toList();

          // Сортируем на стороне клиента (новые сверху)
          tickets.sort((a, b) {
            final timeA = a.timestamp ?? DateTime(1970);
            final timeB = b.timestamp ?? DateTime(1970);
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return TicketCard(
                ticket: ticket,
                onTap: () => _showTicketDetails(context, ticket),
                onStatusChange: () => _changeStatus(context, ticket),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDeviceDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Добавить ПК в базу'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _showTicketDetails(BuildContext context, TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24.0,
          right: 24.0,
          top: 24.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Детали заявки',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow('Описание', ticket.description),
              const SizedBox(height: 16),
              _buildDetailRow('Кабинет', ticket.room),
              _buildDetailRow('ПК', ticket.pcNumber),
              _buildDetailRow('IP-адрес', ticket.deviceIp),
              _buildDetailRow('Сотрудник', ticket.owner),
              _buildDetailRow('ОС', ticket.osName),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _changeStatus(context, ticket);
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('Сменить статус'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _archiveRequest(context, ticket.id),
                      icon: const Icon(Icons.archive, color: Colors.white),
                      label: const Text('В архив', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case RequestStatus.newRequest: return 'Новая';
      case RequestStatus.inProgress: return 'В работе';
      case RequestStatus.done: return 'Выполнено';
      default: return status;
    }
  }

  void _changeStatus(BuildContext context, TicketModel ticket) {
    final firestoreService = FirestoreService();
    
    String nextStatus;
    switch (ticket.status) {
      case RequestStatus.newRequest:
        nextStatus = RequestStatus.inProgress;
        break;
      case RequestStatus.inProgress:
        nextStatus = RequestStatus.done;
        break;
      case RequestStatus.done:
        nextStatus = RequestStatus.newRequest;
        break;
      default:
        nextStatus = RequestStatus.newRequest;
    }

    firestoreService.updateTicketStatus(ticket.id, nextStatus);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус изменен на: ${_getStatusText(nextStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _archiveRequest(BuildContext context, String ticketId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Архивировать заявку?'),
        content: const Text('Заявка будет скрыта из списка, но сохранится в базе данных.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('В архив', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('requests').doc(ticketId).update({
          'is_deleted': true,
          'archived_at': FieldValue.serverTimestamp(),
        });
        
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Заявка архивирована'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showAddDeviceDialog(BuildContext context) {
    final ipController = TextEditingController();
    final roomController = TextEditingController();
    final pcController = TextEditingController();
    final ownerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новое устройство'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'IP-адрес',
                  hintText: '192.168.1.50',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                  labelText: 'Кабинет',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pcController,
                decoration: const InputDecoration(
                  labelText: 'Номер ПК',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerController,
                decoration: const InputDecoration(
                  labelText: 'Сотрудник',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = ipController.text.trim();
              if (ip.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите IP-адрес'), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection(FirestoreCollections.devices)
                    .doc(ip)
                    .set({
                  'ip': ip,
                  'room': roomController.text.trim(),
                  'pc_number': pcController.text.trim(),
                  'owner': ownerController.text.trim(),
                  'created_at': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Устройство добавлено!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Ошибка: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}