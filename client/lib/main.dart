import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/socket_service.dart';
import 'services/game_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RackRushApp());
}

class RackRushApp extends StatelessWidget {
  const RackRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SocketService()),
        ChangeNotifierProxyProvider<SocketService, GameState>(
          create: (_) => GameState(),
          update: (_, socket, game) => game!..updateSocket(socket),
        ),
      ],
      child: MaterialApp(
        title: 'RackRush',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
