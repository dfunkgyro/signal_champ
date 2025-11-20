import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:upgrader/upgrader.dart';
import '../controllers/theme_controller.dart';
import '../controllers/canvas_theme_controller.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/connection_service.dart';
import '../services/sound_service.dart';
import '../services/scenario_service.dart';
import '../services/intent_service.dart';
import '../services/widget_preferences_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/text_to_speech_service.dart';
import '../widgets/connection_indicator.dart';
import 'weather_system.dart';
import 'achievements_service.dart';
import 'custom_bottom_nav.dart';
import '../screens/terminal_station_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/analytics_screen.dart';
import '../controllers/terminal_station_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Starting Rail Champ initialization...');

  // ========== PHASE 1: CRITICAL INFRASTRUCTURE ==========
  debugPrint('📋 PHASE 1: Initializing critical infrastructure...');

  String? openAiApiKey;
  SupabaseClient? supabaseClient;

  try {
    // Load environment variables
    debugPrint('  → Loading environment variables...');
    await dotenv.load(fileName: 'assets/.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    openAiApiKey = dotenv.env['OPENAI_API_KEY'];
    debugPrint('  ✅ Environment variables loaded');

    // Initialize Supabase (CRITICAL - needs time to connect)
    if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      debugPrint('  → Initializing Supabase connection...');
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
      supabaseClient = Supabase.instance.client;
      debugPrint('  ✅ Supabase connection established');

      // WAIT for Supabase to stabilize
      debugPrint('  ⏳ Waiting for Supabase to stabilize (500ms)...');
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('  ✅ Supabase stabilized');
    } else {
      debugPrint('  ⚠️ Supabase credentials missing - running in offline mode');
    }

    // Initialize Sound Service (optional but beneficial to do early)
    try {
      debugPrint('  → Initializing sound service...');
      await SoundService().initialize();
      debugPrint('  ✅ Sound service initialized');
    } catch (e) {
      debugPrint('  ⚠️ Sound service initialization error (optional): $e');
    }
  } catch (e) {
    debugPrint('  ❌ Critical initialization error: $e');
  }

  // Create fallback Supabase client if needed
  if (supabaseClient == null) {
    debugPrint('  → Creating fallback Supabase client...');
    // Don't create a fake client that will fail - just leave it null
    debugPrint('  ⚠️ Running in full offline mode without Supabase');
  }

  debugPrint('✅ PHASE 1 Complete - Critical infrastructure ready\n');

  // ========== PHASE 2: CORE SERVICES ==========
  debugPrint('📋 PHASE 2: Initializing core services...');

  // Small delay before starting service initialization
  await Future.delayed(const Duration(milliseconds: 200));

  final widgetPrefsService = WidgetPreferencesService();
  try {
    debugPrint('  → Initializing widget preferences (SharedPreferences)...');
    await widgetPrefsService.initialize();
    debugPrint('  ✅ Widget preferences initialized');
  } catch (e) {
    debugPrint('  ⚠️ Widget preferences failed (non-critical): $e');
  }

  // Wait between service initializations to prevent resource contention
  await Future.delayed(const Duration(milliseconds: 150));

  debugPrint('✅ PHASE 2 Complete - Core services ready\n');

  // ========== PHASE 3: OPTIONAL FEATURES ==========
  debugPrint('📋 PHASE 3: Initializing optional features...');

  final speechRecognitionService = SpeechRecognitionService();
  try {
    debugPrint('  → Initializing speech recognition...');
    await speechRecognitionService.initialize();
    debugPrint('  ✅ Speech recognition initialized');
  } catch (e) {
    debugPrint('  ⚠️ Speech recognition failed (non-critical): $e');
  }

  // Wait between heavy services
  await Future.delayed(const Duration(milliseconds: 150));

  final ttsService = TextToSpeechService();
  try {
    debugPrint('  → Initializing text-to-speech...');
    await ttsService.initialize();
    debugPrint('  ✅ Text-to-speech initialized');
  } catch (e) {
    debugPrint('  ⚠️ TTS failed (non-critical): $e');
  }

  debugPrint('✅ PHASE 3 Complete - Optional features ready\n');

  // ========== PHASE 4: FINAL PREPARATION ==========
  debugPrint('📋 PHASE 4: Preparing to launch UI...');

  // Final stabilization delay before starting UI
  debugPrint('  ⏳ Final stabilization (300ms)...');
  await Future.delayed(const Duration(milliseconds: 300));

  debugPrint('✅ All initialization complete - Starting app UI\n');
  debugPrint('🎉 Rail Champ ready to launch!\n');

  runApp(RailChampApp(
    supabaseClient: supabaseClient,
    openAiApiKey: openAiApiKey,
    widgetPrefsService: widgetPrefsService,
    speechRecognitionService: speechRecognitionService,
    ttsService: ttsService,
  ));
}

class RailChampApp extends StatelessWidget {
  final SupabaseClient? supabaseClient;
  final String? openAiApiKey;
  final WidgetPreferencesService widgetPrefsService;
  final SpeechRecognitionService speechRecognitionService;
  final TextToSpeechService ttsService;

  const RailChampApp({
    Key? key,
    this.supabaseClient,
    this.openAiApiKey,
    required this.widgetPrefsService,
    required this.speechRecognitionService,
    required this.ttsService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle Supabase client safely - use provided client or try to get instance
    late final SupabaseClient client;
    try {
      client = supabaseClient ?? Supabase.instance.client;
    } catch (e) {
      debugPrint('Supabase not initialized, running in offline mode: $e');
      // Create a mock client with dummy credentials for offline mode
      client = SupabaseClient(
        'https://placeholder.supabase.co',
        'placeholder-anon-key',
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => CanvasThemeController()),
        ChangeNotifierProvider(create: (_) => SupabaseService(client)),
        ChangeNotifierProvider(create: (_) => AuthService(client)),
        ChangeNotifierProvider(create: (_) => AnalyticsService(client)),
        ChangeNotifierProvider(
          create: (_) => ConnectionService(client, openAiApiKey: openAiApiKey),
        ),
        ChangeNotifierProvider(create: (_) => WeatherSystem()),
        ChangeNotifierProvider(create: (_) => AchievementsService(client)),
        ChangeNotifierProvider(create: (_) => ScenarioService(client)),
        ChangeNotifierProvider(create: (_) => TerminalStationController()),
        ChangeNotifierProvider(
          create: (_) {
            final intentService = IntentService();
            intentService.loadIntents(); // Load SSM intents on startup
            return intentService;
          },
        ),
        // NEW: Widget customization and voice services
        ChangeNotifierProvider.value(value: widgetPrefsService),
        ChangeNotifierProvider.value(value: speechRecognitionService),
        ChangeNotifierProvider.value(value: ttsService),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Rail Champ',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.themeMode,
            theme: themeController.getLightTheme(),
            darkTheme: themeController.getDarkTheme(),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Wrapper to handle authentication state and show appropriate screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // Show loading splash while initializing authentication
    if (!authService.isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Icon(
                Icons.train,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              // Loading indicator
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              // Status text
              Text(
                'Initializing Rail Champ...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Checking authentication',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show main screen if authenticated or in guest mode
    if (authService.isAuthenticated) {
      return const MainScreenWithUpgrader();
    }

    // Show login screen
    return const LoginScreen();
  }
}

/// Main screen wrapped with upgrader for force update mechanism
class MainScreenWithUpgrader extends StatelessWidget {
  const MainScreenWithUpgrader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        durationUntilAlertAgain: const Duration(days: 1),
      ),
      child: const MainScreen(),
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
    debugPrint('🔧 MainScreen: Starting service initialization...');

    try {
      // STEP 1: Initialize Supabase presence (if available)
      try {
        debugPrint('  → Initializing Supabase presence...');
        final supabaseService = context.read<SupabaseService>();
        await supabaseService.initializePresence();
        debugPrint('  ✅ Supabase presence initialized');

        // Wait for presence to stabilize
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('  ⚠️ Supabase presence failed (non-critical): $e');
      }

      // STEP 2: Load achievements
      try {
        debugPrint('  → Loading achievements...');
        final achievements = context.read<AchievementsService>();
        await achievements.loadEarnedAchievements();
        debugPrint('  ✅ Achievements loaded');

        // Small delay before next service
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (e) {
        debugPrint('  ⚠️ Achievements loading failed (non-critical): $e');
      }

      // STEP 3: Start connection monitoring
      try {
        debugPrint('  → Starting connection monitoring...');
        final connectionService = context.read<ConnectionService>();
        await connectionService.checkAllConnections();
        debugPrint('  ✅ Connection monitoring started');

        // Small delay before analytics
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('  ⚠️ Connection monitoring failed (non-critical): $e');
      }

      // STEP 4: Log app open event (analytics - low priority)
      try {
        debugPrint('  → Logging app open event...');
        final analyticsService = context.read<AnalyticsService>();
        await analyticsService.logEvent('app_opened');
        debugPrint('  ✅ App open event logged');
      } catch (e) {
        debugPrint('  ⚠️ Analytics logging failed (non-critical): $e');
      }

      debugPrint('✅ MainScreen: All services initialized successfully\n');
    } catch (e) {
      debugPrint('❌ MainScreen: Service initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TerminalStationScreen(), // ✅ Terminal station with crossover!
          AnalyticsScreen(), // 📊 Analytics tab
          SettingsScreen(), // ⚙️ Settings tab
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
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ConnectionIndicator(),
          ),
        ],
      ),
      body: ListView(
        children: [
          // User Info Section
          if (authService.isAuthenticated) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                child: Icon(
                  authService.isGuest ? Icons.person_outline : Icons.person,
                ),
              ),
              title: Text(authService.displayName),
              subtitle: Text(authService.userEmail ?? 'No email'),
              trailing: authService.isGuest
                  ? Chip(
                      label: const Text('Guest'),
                      backgroundColor: Colors.orange.withOpacity(0.2),
                    )
                  : null,
            ),
            const Divider(),
          ],

          // Connection Status
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Connection Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ConnectionIndicator(showDetails: true),
          ),
          const Divider(),

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
          const Divider(),

          // Logout Button
          if (authService.isAuthenticated)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await context.read<AuthService>().signOut();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
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
