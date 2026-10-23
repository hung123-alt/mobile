
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
    apiKey: 'AIzaSyBDTqJpixcj5fF6KUUY4xieg_5TOC867_M',
    appId: '1:797999836605:web:7688a386eb0adf57cf76d4',
    messagingSenderId: '797999836605',
    projectId: 'cinema-app-b760e',
    authDomain: 'cinema-app-b760e.firebaseapp.com',
    storageBucket: 'cinema-app-b760e.firebasestorage.app',
    measurementId: 'G-3TX4BC8LGY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6ZYUUJQVDz-ks-tEI4bRDrjaRqPJPr-s',
    appId: '1:797999836605:android:be219729f2c2a504cf76d4',
    messagingSenderId: '797999836605',
    projectId: 'cinema-app-b760e',
    storageBucket: 'cinema-app-b760e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA2qSyGDMmk4xg9XFQaAtH2gsQGJeLPmeI',
    appId: '1:797999836605:ios:f09345419f598149cf76d4',
    messagingSenderId: '797999836605',
    projectId: 'cinema-app-b760e',
    storageBucket: 'cinema-app-b760e.firebasestorage.app',
    iosBundleId: 'com.example.cinemaApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA2qSyGDMmk4xg9XFQaAtH2gsQGJeLPmeI',
    appId: '1:797999836605:ios:f09345419f598149cf76d4',
    messagingSenderId: '797999836605',
    projectId: 'cinema-app-b760e',
    storageBucket: 'cinema-app-b760e.firebasestorage.app',
    iosBundleId: 'com.example.cinemaApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBDTqJpixcj5fF6KUUY4xieg_5TOC867_M',
    appId: '1:797999836605:web:6d301dc047c8fc82cf76d4',
    messagingSenderId: '797999836605',
    projectId: 'cinema-app-b760e',
    authDomain: 'cinema-app-b760e.firebaseapp.com',
    storageBucket: 'cinema-app-b760e.firebasestorage.app',
    measurementId: 'G-MZBZ1EMCMG',
  );
}
