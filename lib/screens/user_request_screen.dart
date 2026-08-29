import 'package:flutter/material.dart';
import '../services/device_service.dart';
import '../services/firestore_service.dart';
import 'user_history_screen.dart';

class UserRequestScreen extends StatefulWidget {
  final bool showHistoryOnly;
  
  const UserRequestScreen({super.key, this.showHistoryOnly = false});

  @override
  State<UserRequestScreen> createState() => _UserRequestScreenState();
}

class _UserRequestScreenState extends State<UserRequestScreen> {
  final TextEditingController _descController = TextEditingController();
  final DeviceService _deviceService = DeviceService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String _statusText = '';

  Future<void> _submitTicket() async {
    if (_descController.text.trim().isEmpty) {
      _showMessage('Пожалуйста, опишите проблему', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = 'Определяем ваше устройство...';
    });

    try {
      final deviceId = await _deviceService.getDeviceId();
      final ip = await _deviceService.getIpAddress();

      setState(() => _statusText = 'Ищем информацию о кабинете...');

      final deviceInfo = await _firestoreService.getDeviceInfoByIp(ip);

      final room = deviceInfo?['room'] ?? 'Не определен';
      final pcNumber = deviceInfo?['pc_number'] ?? 'Не указан';
      final owner = deviceInfo?['owner'] ?? 'Сотрудник';
      final osName = _deviceService.getOsName();

      setState(() => _statusText = 'Отправляем заявку...');

      await _firestoreService.submitRequest(
        deviceId: deviceId,
        ip: ip,
        description: _descController.text.trim(),
        room: room,
        pcNumber: pcNumber,
        owner: owner,
        osName: osName,
      );

      _showMessage('Заявка успешно отправлена! Ожидайте.', Colors.green);
      _descController.clear();
      setState(() => _statusText = '');
    } catch (e) {
      _showMessage('Ошибка отправки: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showHistoryOnly) {
      return const UserHistoryScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тикетик'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Что случилось?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Мы автоматически определим ваш ПК и кабинет по сети.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _descController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Например: Не работает принтер, нет интернета...',
                labelText: 'Описание проблемы',
              ),
            ),
            const SizedBox(height: 24),
            if (_statusText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _statusText,
                  style: TextStyle(
                    color: _isLoading ? Colors.blue : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitTicket,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Отправка...' : 'Отправить'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserHistoryScreen()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('История моих заявок'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
