import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants.dart';
import 'services/notification_service.dart';
import 'services/reminder_restore_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/tasks/task_list_screen.dart';
import 'screens/tasks/create_task_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройка статус бара - светлый фон, тёмные иконки и текст
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF5F7FA),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      statusBarBrightness: Brightness.dark,
    ),
  );

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await NotificationService().initialize();

  runApp(const ProviderScope(child: TaskTrackerApp()));
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Адаптивные размеры для веба
    final isWeb = kIsWeb;
    final baseFontSize = isWeb ? 18.0 : 14.0;
    final titleFontSize = isWeb ? 26.0 : 20.0;
    
    return GestureDetector(
      onTap: () {
        // Скрываем клавиатуру при тапе на свободную область
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ru', 'RU'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          ),
          color: Colors.white.withValues(alpha: 0.7),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF1F2937),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFFF5F7FA),
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            size: isWeb ? 28 : 24,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 8,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
          ),
          extendedTextStyle: TextStyle(
            fontSize: isWeb ? 18 : 14,
            fontWeight: FontWeight.w600,
          ),
          extendedIconLabelSpacing: isWeb ? 12 : 8,
          extendedPadding: EdgeInsets.symmetric(
            horizontal: isWeb ? 28 : 20,
            vertical: isWeb ? 18 : 12,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.8),
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: baseFontSize,
          ),
          labelStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: baseFontSize,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: baseFontSize,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
            borderSide: BorderSide(
              color: const Color(0xFF6366F1), 
              width: isWeb ? 3 : 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isWeb ? 24 : 20, 
            vertical: isWeb ? 20 : 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              vertical: isWeb ? 20 : 16, 
              horizontal: isWeb ? 32 : 24,
            ),
            textStyle: TextStyle(
              fontSize: isWeb ? 18 : 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
            ),
            elevation: 4,
            minimumSize: Size(isWeb ? 120 : 88, isWeb ? 56 : 48),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: baseFontSize,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 16 : 12, 
            vertical: isWeb ? 10 : 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
          ),
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(fontSize: isWeb ? 16 : 12),
          bodyMedium: TextStyle(fontSize: baseFontSize),
          bodyLarge: TextStyle(fontSize: isWeb ? 20 : 16),
          titleSmall: TextStyle(fontSize: baseFontSize),
          titleMedium: TextStyle(fontSize: isWeb ? 20 : 16),
          titleLarge: TextStyle(fontSize: isWeb ? 24 : 20),
        ),
        iconTheme: IconThemeData(
          size: isWeb ? 26 : 20,
        ),
      ),
      home: const EntryWrapper(),
    ),
    );
  }
}

class EntryWrapper extends StatefulWidget {
  const EntryWrapper({super.key});

  @override
  State<EntryWrapper> createState() => _EntryWrapperState();
}

class _EntryWrapperState extends State<EntryWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAuthListener();
    _restoreRemindersOnStartup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // При возврате в фокус восстанавливаем напоминания
    if (state == AppLifecycleState.resumed) {
      _restoreRemindersOnStartup();
    }
  }

  Future<void> _restoreRemindersOnStartup() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await ReminderRestoreService().restoreRemindersAfterBoot();
      }
    } catch (e) {
      print('⚠️ Ошибка при восстановлении напоминаний: $e');
    }
  }

  void _setupAuthListener() {
    // Слушаем изменения состояния авторизации
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          // Перестраиваем виджет при изменении сессии
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Если пользователь не авторизован, показываем экран входа
    if (Supabase.instance.client.auth.currentSession == null) {
      return const LoginScreen();
    }

    // Если авторизован, показываем главный экран
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _hasShownPermissionDialog = false;

  final List<Widget> _screens = const [TaskListScreen(), SettingsScreen()];

  @override
  void initState() {
    super.initState();
    // Проверяем разрешения после первого фрейма
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAlarmPermission();
    });
  }

  Future<void> _checkAlarmPermission() async {
    if (_hasShownPermissionDialog) return;
    _hasShownPermissionDialog = true;

    final notificationService = NotificationService();
    final hasPermission = await notificationService.hasExactAlarmPermission();

    // Показываем полный диалог если нет разрешения на будильники
    if (hasPermission == false && mounted) {
      await notificationService.showAllPermissionsDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTaskScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Новая задача'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        indicatorColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
