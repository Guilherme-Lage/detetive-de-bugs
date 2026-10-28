// Configuração do projeto Firebase "detetives-de-bugs-1d317" (app Web).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Firebase configurado apenas para Web. Execute com: flutter run -d chrome');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBLPGmCK6fdIGMED5mssGF45047y5QGatY',
    appId: '1:107711331562:web:1c0f365c773634a3cd2b93',
    messagingSenderId: '107711331562',
    projectId: 'detetives-de-bugs-1d317',
    authDomain: 'detetives-de-bugs-1d317.firebaseapp.com',
    storageBucket: 'detetives-de-bugs-1d317.firebasestorage.app',
    measurementId: 'G-GHDBT48M5C',
  );
}
