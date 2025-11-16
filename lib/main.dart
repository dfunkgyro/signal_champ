import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers/theme_controller.dart';
import '../services/supabase_service.dart';
import 'weather_system.dart';
import 'achievements_service.dart';
import 'custom_bottom_nav.dart';
import '../screens/terminal_station_screen.dart';
import '../controllers/terminal_station_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'assets/.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    }
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(const RailChampApp());
}

class RailChampApp extends StatelessWidget {
  const RailChampApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => SupabaseService(Supabase.instance.client),
        ),
        ChangeNotifierProvider(create: (_) => WeatherSystem()),
        ChangeNotifierProvider(
          create: (_) => AchievementsService(Supabase.instance.client),
        ),
        // Terminal station with crossover and route setting
        ChangeNotifierProvider(create: (_) => TerminalStationController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Rail Champ',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.themeMode,
            theme: themeController.getLightTheme(),
            darkTheme: themeController.getDarkTheme(),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Start on simulation screen

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize Supabase presence
      final supabaseService = context.read<SupabaseService>();
      await supabaseService.initializePresence();

      // Load achievements
      final achievements = context.read<AchievementsService>();
      await achievements.loadEarnedAchievements();
    } catch (e) {
      debugPrint('Service initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TerminalStationScreen(), // ✅ Terminal station with crossover!
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                context.read<TerminalStationController>().addTrain();
              },
              child: const Icon(Icons.add),
              tooltip: 'Add Train',
            )
          : null,
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Theme Mode'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
              ],
              selected: {themeController.themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                themeController.setThemeMode(newSelection.first);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('App Theme'),
            trailing: DropdownButton<AppTheme>(
              value: themeController.currentTheme,
              onChanged: (theme) {
                if (theme != null) {
                  themeController.setAppTheme(theme);
                }
              },
              items: AppTheme.values.map((theme) {
                return DropdownMenuItem(
                  value: theme,
                  child: Text(_getThemeName(theme)),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Simulation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Consumer<WeatherSystem>(
            builder: (context, weather, _) {
              return SwitchListTile(
                title: const Text('Weather Effects'),
                subtitle: Text('Current: ${weather.getWeatherDescription()}'),
                value: weather.currentWeather != WeatherCondition.clear,
                onChanged: (value) {
                  if (value) {
                    weather.setWeather(WeatherCondition.rain);
                  } else {
                    weather.setWeather(WeatherCondition.clear);
                  }
                },
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('2.1.0 (Enhanced)'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report Issue'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Documentation'),
            onTap: () {
              _showHelp(context);
            },
          ),
        ],
      ),
    );
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.railway:
        return 'Railway';
      case AppTheme.midnight:
        return 'Midnight';
      case AppTheme.sunset:
        return 'Sunset';
      case AppTheme.forest:
        return 'Forest';
      case AppTheme.ocean:
        return 'Ocean';
      case AppTheme.monochrome:
        return 'Monochrome';
      case AppTheme.highContrast:
        return 'High Contrast';
    }
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rail Champ Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Simulation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Control and monitor train operations'),
              SizedBox(height: 12),
              Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Customize app appearance and behavior'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
