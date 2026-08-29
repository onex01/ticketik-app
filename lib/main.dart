import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/user_request_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TicketikApp());
}

class TicketikApp extends StatelessWidget {
  const TicketikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Тикетик',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  int _tapCount = 0;

  Future<void> _checkAdminPin(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вход для администратора'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Введите PIN-код'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Войти'),
          ),
        ],
      ),
    );

    if (result == '410022') {
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
    } else if (result != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный PIN-код'), backgroundColor: Colors.red),
      );
    }
    setState(() => _tapCount = 0); // Сброс счетчика
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Скрытый триггер: 5 быстрых нажатий на название
              GestureDetector(
                onDoubleTap: () {
                  setState(() => _tapCount += 2);
                  if (_tapCount >= 5) _checkAdminPin(context);
                },
                onTap: () {
                  setState(() => _tapCount++);
                  if (_tapCount >= 5) _checkAdminPin(context);
                  // Сброс счетчика через 2 секунды бездействия
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _tapCount = 0);
                  });
                },
                child: const Text(
                  'Тикетик',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ),
              const SizedBox(height: 16),
              Text('Отправить запрос', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              const SizedBox(height: 64),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserRequestScreen())),
                icon: const Icon(Icons.person, size: 24),
                label: const Text('Отправить запрос', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}