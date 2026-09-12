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
      title: 'RETRO TASK // 跨端待办看板',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFDF8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFEF08A),
          primary: Colors.black,
          secondary: const Color(0xFF38BDF8),
          surface: const Color(0xFFFFFDF8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black, width: 2.5),
          ),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
