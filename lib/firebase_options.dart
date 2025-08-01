// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAJyYak8LtKIcF-WfghX5NcRzni2KYlRm4',
    appId: '1:80025318352:web:081c4e0dcee78d82373fd5',
    messagingSenderId: '80025318352',
    projectId: 'swypshyt-finance',
    authDomain: 'swypshyt-finance.firebaseapp.com',
    storageBucket: 'swypshyt-finance.firebasestorage.app',
    measurementId: 'G-MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAJyYak8LtKIcF-WfghX5NcRzni2KYlRm4',
    appId: '1:80025318352:android:081c4e0dcee78d82373fd5',
    messagingSenderId: '80025318352',
    projectId: 'swypshyt-finance',
    storageBucket: 'swypshyt-finance.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAJyYak8LtKIcF-WfghX5NcRzni2KYlRm4',
    appId: '1:80025318352:ios:081c4e0dcee78d82373fd5',
    messagingSenderId: '80025318352',
    projectId: 'swypshyt-finance',
    storageBucket: 'swypshyt-finance.firebasestorage.app',
    iosBundleId: 'com.example.swypshyt',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAJyYak8LtKIcF-WfghX5NcRzni2KYlRm4',
    appId: '1:80025318352:ios:081c4e0dcee78d82373fd5',
    messagingSenderId: '80025318352',
    projectId: 'swypshyt-finance',
    storageBucket: 'swypshyt-finance.firebasestorage.app',
    iosBundleId: 'com.example.swypshyt',
  );
}
