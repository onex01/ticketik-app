import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ticket_model.dart';
import '../widgets/ticket_card.dart';
import '../services/firestore_service.dart';
import '../core/constants.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    
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
        stream: firestoreService.getActiveTicketsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Если ошибка связана с индексом, показываем сообщение с кнопкой
            final errorMsg = snapshot.error.toString();
            if (errorMsg.contains('index') || errorMsg.contains('failed-precondition')) {
              const indexUrl = 'https://console.firebase.google.com/v1/r/project/ticketik-app/firestore/indexes?create_composite=Ck1wcm9qZWN0cy90aWNrZXRpay1hcHAvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3JlcXVlc3RzL2luZGV4ZXMvXxABGg0KCWRldmljZV9pcBABGg4KCmlzX2RlbGV0ZWQQARONCgl0aW1lc3RhbXAQAhoMCghfX25hbWVfXxAC';
              
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'Требуется создать индекс в Firestore',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Нажмите кнопку ниже, чтобы открыть консоль Firebase и создать индекс автоматически.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Создать индекс в Firebase'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(indexUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Не удалось открыть ссылку. Скопируйте её вручную.')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
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
            if (!ticket.isDeleted)
              ElevatedButton.icon(
                icon: const Icon(Icons.archive, color: Colors.white),
                label: const Text('Архивировать заявку', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Подтверждение'),
                      content: const Text('Заявка будет скрыта из пользовательской истории, но останется в базе.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Архивировать')),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await FirestoreService().softDeleteTicket(ticket.id);
                    if (context.mounted) Navigator.pop(context);
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
    final firestoreService = FirestoreService();

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
                keyboardType: TextInputType.text,
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
              
              // Простая валидация IP-адреса
              final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
              if (!ipPattern.hasMatch(ipController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Неверный формат IP-адреса'), backgroundColor: Colors.red),
                );
                return;
              }
              
              try {
                await firestoreService.addDevice(
                  ip: ipController.text.trim(),
                  room: roomController.text.trim(),
                  pcNumber: pcController.text.trim(),
                  owner: ownerController.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Устройство добавлено!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
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