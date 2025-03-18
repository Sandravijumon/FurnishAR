import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:placeit/Admin/admin_page.dart';
import 'package:placeit/User/user_page.dart';
import 'package:placeit/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  // Lock the app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style system UI overlays (status and navigation bars)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Request storage permission
  await _requestStoragePermission();

  runApp(const MyApp());
}

Future<void> _requestStoragePermission() async {
  // For Android 13+ (API 33+), use granular media permissions
  if (await Permission.photos.isDenied) {
    await Permission.photos.request();
  }
  if (await Permission.videos.isDenied) {
    await Permission.videos.request();
  }
  if (await Permission.audio.isDenied) {
    await Permission.audio.request();
  }

  // For Android 12 and below, use legacy storage permission
  var storageStatus = await Permission.storage.status;
  if (storageStatus.isDenied) {
    storageStatus = await Permission.storage.request();
  }

  // Handle the result
  if (storageStatus.isDenied || (await Permission.photos.isDenied && await Permission.videos.isDenied && await Permission.audio.isDenied)) {
    print('Storage permission denied');
  } else if (storageStatus.isPermanentlyDenied || await Permission.photos.isPermanentlyDenied || await Permission.videos.isPermanentlyDenied || await Permission.audio.isPermanentlyDenied) {
    print('Storage permission permanently denied');
    await openAppSettings(); // Guide user to app settings
  } else if (storageStatus.isGranted || await Permission.photos.isGranted || await Permission.videos.isGranted || await Permission.audio.isGranted) {
    print('Storage permission granted');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? initialScreen;

  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
  }

  Future<void> _determineInitialScreen() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (currentUser.email == 'admin@gmail.com') {
        setState(() {
          initialScreen = const AdminPage();
        });
      } else {
        setState(() {
          initialScreen = const UserPage();
        });
      }
    } else {
      setState(() {
        initialScreen = const SplashScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Placeit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: initialScreen ??
          const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
    );
  }
}