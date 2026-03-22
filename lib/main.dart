import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'firebase_options.dart';
import 'features/onboarding/app_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.operonte.coroapp.channel.audio',
    androidNotificationChannelName: 'Reproducción de audio',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'CoroApp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C3E80),
            brightness: Brightness.light,
          ).copyWith(
            primary: const Color(0xFF2C3E80),
            secondary: const Color(0xFFD4A84B),
          ),
          textTheme: GoogleFonts.sourceSans3TextTheme(
            ThemeData.light().textTheme,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2C3E80),
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.sourceSans3(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          useMaterial3: true,
        ),
        home: const AppInitializer(),
      ),
    );
  }
}
