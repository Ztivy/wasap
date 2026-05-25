import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/routes/routes.dart';
import 'package:wasap2/common/theme/dark_theme.dart';
import 'package:wasap2/common/theme/light_theme.dart';
import 'package:wasap2/feature/auth/controller/auth_controller.dart';
import 'package:wasap2/feature/auth/pages/user_info_page.dart';
import 'package:wasap2/feature/contact/pages/contact_page.dart';
import 'package:wasap2/feature/home/pages/home_page.dart';
import 'package:wasap2/feature/welcome/pages/welcome_page.dart';
import 'package:wasap2/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsBinding widgetsBinding= WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  await Supabase.initialize(
    url: 'https://sccxcxdpabvasbuaybiws.supabase.co',
    anonKey: 'sb_publishable_zNWGest9u5VIerf5V1DH9Q_IspXCpbTs',
  );
  runApp(const ProviderScope(child: MyApp(),),);
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whatsapp Clone',
      theme: lightTheme(),
      darkTheme:darkTheme(),
      themeMode: ThemeMode.system,
      home: ref.watch(userInfoAuthProvider).when(
        data: (user){
          FlutterNativeSplash.remove();
          if(user==null) return const WelcomePage();
          return const HomePage();
        },
        error: (error,trace){
          return Scaffold(body: Center(child: Text('Something wrong happen!'),),);
        },
        loading: (){
          return const SizedBox();
        }
      ),
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}