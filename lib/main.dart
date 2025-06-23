import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindmapping/Services/data_service.dart';
import 'package:mindmapping/Services/project_storage.dart';
import 'package:mindmapping/View/splash.view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
// Dans votre main.dart ou au début de l'app
Get.put(ProjectStorage());
Get.put(MindMapDataService());
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Splash(),
    );
  }
}