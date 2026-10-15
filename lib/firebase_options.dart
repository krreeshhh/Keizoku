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
        return linux;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAQ_z2qONHu5kECscIrZALLZ16i1pGOGSk',
    appId: '1:171443563500:web:4c9228d7a373ee2c15eec9',
    messagingSenderId: '171443563500',
    projectId: 'gym-application-f3fe4',
    authDomain: 'gym-application-f3fe4.firebaseapp.com',
    storageBucket: 'gym-application-f3fe4.firebasestorage.app',
    measurementId: 'G-VZZEBYRL1W',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB41ALLHwavZdF_gjpu4Bx2WR0ubqS27XI',
    appId: '1:171443563500:android:e85e75598f1c592015eec9',
    messagingSenderId: '171443563500',
    projectId: 'gym-application-f3fe4',
    storageBucket: 'gym-application-f3fe4.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDA2GPkPchP1GUoNEFaMkfvgWsYzJAjpJ8',
    appId: '1:171443563500:ios:ff29b2586a4db3f715eec9',
    messagingSenderId: '171443563500',
    projectId: 'gym-application-f3fe4',
    storageBucket: 'gym-application-f3fe4.firebasestorage.app',
    iosBundleId: 'com.keizoku.app',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDA2GPkPchP1GUoNEFaMkfvgWsYzJAjpJ8',
    appId: '1:171443563500:ios:ff29b2586a4db3f715eec9',
    messagingSenderId: '171443563500',
    projectId: 'gym-application-f3fe4',
    storageBucket: 'gym-application-f3fe4.firebasestorage.app',
    iosBundleId: 'com.keizoku.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAQ_z2qONHu5kECscIrZALLZ16i1pGOGSk',
    appId: '1:171443563500:web:fb1a33bf5db0941915eec9',
    messagingSenderId: '171443563500',
    projectId: 'gym-application-f3fe4',
    authDomain: 'gym-application-f3fe4.firebaseapp.com',
    storageBucket: 'gym-application-f3fe4.firebasestorage.app',
    measurementId: 'G-G2S3J4VWD3',
  );
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyA_KeizokuWebApiKey_Placeholder123',
    appId: '1:100000000000:web:keizoku123456',
    messagingSenderId: '100000000000',
    projectId: 'keizoku-social',
    authDomain: 'keizoku-social.firebaseapp.com',
    storageBucket: 'keizoku-social.appspot.com',
  );
}
