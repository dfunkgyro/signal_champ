import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/supabase_status_provider.dart';
import 'providers/terminal_editor_provider.dart';
import 'screens/terminal_editor_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TerminalEditorProvider()),
        ChangeNotifierProvider(
          create: (_) => SupabaseStatusProvider()..checkConnection(),
        ),
      ],
      child: MaterialApp(
        title: 'Terminal Station Editor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const TerminalEditorScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
