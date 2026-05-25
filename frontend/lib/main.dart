import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app_router.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/core/storage/hive_client.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/common_widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await HiveClient.init();
  await initSupabase();

  // Khởi tạo RevenueCat từ Phase 9
  // await SubscriptionRepository(Supabase.instance.client).init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'How r u bro?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // Tự động theo hệ điều hành
      home: const SplashScreen(), 
    );
  }
}
