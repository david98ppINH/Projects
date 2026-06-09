import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

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
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAV5ylechIY8CjSRJ55URwgNVXHtSLXUtA',
    appId: '1:499820674603:web:6356f1d920e9532641f46e',
    messagingSenderId: '499820674603',
    projectId: 'bda-games-fan-fest',
    authDomain: 'bda-games-fan-fest.firebaseapp.com',
    storageBucket: 'bda-games-fan-fest.firebasestorage.app',
    measurementId: 'G-6H7Z84MYZJ',
  );
}
