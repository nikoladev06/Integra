import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:proj_compras/view/inicio_view.dart';
import 'package:proj_compras/view/cadastrar_view.dart';
import 'package:proj_compras/view/login_view.dart';
import 'package:proj_compras/view/recuperarsenha_view.dart';
import 'package:proj_compras/view/sobre_view.dart';
import 'package:proj_compras/view/home_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Garante que os bindings do Flutter estejam prontos antes de qualquer outra coisa.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  runApp(
    DevicePreview(
      enabled: true, 
      builder: (context) => const MainApp(),
      )
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'Navegação',
      initialRoute: 'inicio',
      routes: {
        'inicio': (context) => InicioView(),
        'cadastrar': (context) => CadastrarView(),
        'login': (context) => LoginView(),
        'recuperar' : (context) => RecuperarsenhaView(),
        'principal' : (context) => const HomeView(),
        'sobre' : (context) => const SobreView(),
      }
    );
  }
}