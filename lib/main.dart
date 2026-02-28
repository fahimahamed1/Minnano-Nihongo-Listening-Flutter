import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/audio_provider.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation before app starts
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Set system UI style to match splash screen
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFAFAFA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MinnanoNihongoApp());
}

class MinnanoNihongoApp extends StatelessWidget {
  const MinnanoNihongoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
      ],
      child: MaterialApp(
        title: 'Minnano Nihongo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Ensure smooth transition from splash
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
