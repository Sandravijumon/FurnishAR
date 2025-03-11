// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSdwfAMcvSr6jtWx861iurxAw_ywRJk3g',
    appId: '1:907576719635:web:970304292adaa968f942e6',
    messagingSenderId: '907576719635',
    projectId: 'furnishar-mainproject-final',
    authDomain: 'furnishar-mainproject-final.firebaseapp.com',
    storageBucket: 'furnishar-mainproject-final.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7LJu2F7rD7t_jVaeIIgGr-X2xpwRonGs',
    appId: '1:907576719635:android:c1fab9349388a81bf942e6',
    messagingSenderId: '907576719635',
    projectId: 'furnishar-mainproject-final',
    storageBucket: 'furnishar-mainproject-final.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCuEu2IOFJyCQapIB9ClfFhHJweJOv72yc',
    appId: '1:907576719635:ios:48b3739276acc17cf942e6',
    messagingSenderId: '907576719635',
    projectId: 'furnishar-mainproject-final',
    storageBucket: 'furnishar-mainproject-final.firebasestorage.app',
    iosBundleId: 'com.example.furnishhArApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCuEu2IOFJyCQapIB9ClfFhHJweJOv72yc',
    appId: '1:907576719635:ios:48b3739276acc17cf942e6',
    messagingSenderId: '907576719635',
    projectId: 'furnishar-mainproject-final',
    storageBucket: 'furnishar-mainproject-final.firebasestorage.app',
    iosBundleId: 'com.example.furnishhArApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBSdwfAMcvSr6jtWx861iurxAw_ywRJk3g',
    appId: '1:907576719635:web:29afa7d5a6182765f942e6',
    messagingSenderId: '907576719635',
    projectId: 'furnishar-mainproject-final',
    authDomain: 'furnishar-mainproject-final.firebaseapp.com',
    storageBucket: 'furnishar-mainproject-final.firebasestorage.app',
  );
}
