import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'screens/home_screen.dart';
import 'services/audio_handler_service.dart';

late AudioHandlerService audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar AudioService correctamente
  audioHandler = await AudioService.init(
    builder: () => AudioHandlerService(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.my_reproductor_v7.audio',
      androidNotificationChannelName: 'Reproductor de Música',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      androidNotificationChannelDescription: 'Controles de reproducción de música',
      notificationColor: Color(0xFF1E88E5),
    ),
  );
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Reproductor',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.purple,
      ),
      home: const HomeScreen(),
    );
  }
}
