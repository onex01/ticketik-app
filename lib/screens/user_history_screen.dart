import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/device_service.dart';
import '../services/firestore_service.dart';
import '../core/constants.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  final DeviceService _deviceService = DeviceService();
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentIp;
  
  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    final ip = await _deviceService.getIpAddress();
    setState(() => _currentIp = ip);
  }

  Future<void> _resendRequest(Map<String, dynamic> data) async {
    final description = data['description'] ?? 'Без описания';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Повторная отправка'),
        content: Text('Отправить эту заявку еще раз?\n\n"$description"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Да, отправить')),
        ],
      ),
    );

    if (confirm == true && _currentIp != null) {
      try {
        final deviceId = await _deviceService.getDeviceId();
        final osName = _deviceService.getOsName();
        
        // Пытаемся получить информацию об устройстве из базы
        final deviceInfo = await _firestoreService.getDeviceInfoByIp(_currentIp!);
        
        await _firestoreService.submitRequest(
          deviceId: deviceId,
          ip: _currentIp!,
          description: description,
          room: deviceInfo?['room'] ?? 'Не определен',
          pcNumber: deviceInfo?['pc_number'] ?? 'Не указан',
          owner: deviceInfo?['owner'] ?? 'Сотрудник',
          osName: osName,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Заявка успешно отправлена повторно!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case RequestStatus.newRequest: return 'Новая';
      case RequestStatus.inProgress: return 'В работе';
      case RequestStatus.done: return 'Выполнено';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIp == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('История заявок')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserHistoryStream(_currentIp!),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Ошибка: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('У вас пока нет заявок', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final desc = data['description'] ?? 'Без описания';
              final status = data['status'] ?? 'new';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: timestamp != null 
                      ? Text('${_getStatusText(status)} • ${timestamp.day}.${timestamp.month}.${timestamp.year}')
                      : Text(_getStatusText(status)),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.indigo),
                    tooltip: 'Отправить повторно',
                    onPressed: () => _resendRequest(data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
