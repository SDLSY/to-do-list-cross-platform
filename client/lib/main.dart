import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/todo_provider.dart';
import 'services/pocketbase_service.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = PocketBaseService();
  final todoProvider = TodoProvider(apiService);

  // 初始化服务并拉取初始数据
  await todoProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: todoProvider),
      ],
      child: const TodoSyncApp(),
    ),
  );
}

class TodoSyncApp extends StatelessWidget {
  const TodoSyncApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '跨平台待办与看板',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // 经典优雅蓝
          brightness: Brightness.light,
        ),
        cardTheme: const CardTheme(
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
