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
            onPressed: () {
              // Обновление произойдет автоматически благодаря StreamBuilder
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirestoreCollections.requests)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Заявок пока нет',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final tickets = snapshot.data!.docs
              .map((doc) => TicketModel.fromFirestore(doc))
              .toList();

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
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Описание проблемы',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(ticket.description, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Text('Кабинет: ${ticket.room}', style: TextStyle(fontSize: 16)),
            Text('ПК: ${ticket.pcNumber}', style: TextStyle(fontSize: 16)),
            Text('IP: ${ticket.deviceIp}', style: TextStyle(fontSize: 16)),
            Text('Сотрудник: ${ticket.owner}', style: TextStyle(fontSize: 16)),
            Text('ОС: ${ticket.osName}', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _changeStatus(context, ticket);
              },
              child: const Text('Изменить статус'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('Удалить заявку', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Подтверждение'),
                    content: const Text('Вы уверены, что хотите удалить эту заявку?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await FirebaseFirestore.instance.collection('requests').doc(ticket.id).delete();
                  if (context.mounted) Navigator.pop(context); // Закрываем модалку
                }
              },
            ),
          ],
        ),
      ),
    );
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
                decoration: const InputDecoration(labelText: 'IP-адрес (напр. 192.168.1.50)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(labelText: 'Кабинет'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pcController,
                decoration: const InputDecoration(labelText: 'Номер ПК'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerController,
                decoration: const InputDecoration(labelText: 'Сотрудник (опционально)'),
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
              if (ipController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите IP-адрес'), backgroundColor: Colors.red),
                );
                return;
              }
              
              await FirebaseFirestore.instance
                  .collection('devices')
                  .doc(ipController.text)
                  .set({
                'ip': ipController.text,
                'room': roomController.text,
                'pc_number': pcController.text,
                'owner': ownerController.text,
              });
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Устройство добавлено!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}