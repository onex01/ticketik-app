import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/user_request_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TicketikApp());
}

class TicketikApp extends StatefulWidget {
  const TicketikApp({super.key});

  @override
  State<TicketikApp> createState() => _TicketikAppState();
}

class _TicketikAppState extends State<TicketikApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0; // 0=system, 1=light, 2=dark
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    setState(() => _themeMode = mode);
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Как в системе'),
              onTap: () {
                Navigator.pop(context);
                _setThemeMode(ThemeMode.system);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Светлая'),
              onTap: () {
                Navigator.pop(context);
                _setThemeMode(ThemeMode.light);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Тёмная'),
              onTap: () {
                Navigator.pop(context);
                _setThemeMode(ThemeMode.dark);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Тикетик',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: RoleSelectionScreen(onThemeChange: _showThemeDialog),
    );
  }
}

class RoleSelectionScreen extends StatefulWidget {
  final Function(BuildContext) onThemeChange;
  
  const RoleSelectionScreen({super.key, required this.onThemeChange});

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
    setState(() => _tapCount = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тикетик'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () => widget.onThemeChange(context),
            tooltip: 'Сменить тему',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onDoubleTap: () {
                  setState(() => _tapCount += 2);
                  if (_tapCount >= 5) _checkAdminPin(context);
                },
                onTap: () {
                  setState(() => _tapCount++);
                  if (_tapCount >= 5) _checkAdminPin(context);
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
              Text('Быстрая отправка заявки в техподдержку', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 64),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserRequestScreen())),
                icon: const Icon(Icons.send, size: 24),
                label: const Text('Отправить запрос', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 48)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserRequestScreen(showHistoryOnly: true))),
                icon: const Icon(Icons.history, size: 24),
                label: const Text('История заявок', style: TextStyle(fontSize: 18)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
