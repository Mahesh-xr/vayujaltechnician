

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCObIJQlKDfl-z5zAOdwnfYf0X_kWbunjg',
    appId: '1:148518126293:android:806a07bdeee5f13346d85c',
    messagingSenderId: '148518126293',
    projectId: 'vayujal-db-for-device-customer',
    storageBucket: 'vayujal-db-for-device-customer.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAT5me80HiTgszAgiDcRdm4HL1scxI8TKM',
    appId: '1:148518126293:ios:36520b44002c31ec46d85c',
    messagingSenderId: '148518126293',
    projectId: 'vayujal-db-for-device-customer',
    storageBucket: 'vayujal-db-for-device-customer.firebasestorage.app',
    iosBundleId: 'com.example.vayujalTechnician',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAiEWFFM2NaXIPHORpLaBebYlHRb73f4b8',
    appId: '1:205934383175:ios:02bcc6913e6c53ab752162',
    messagingSenderId: '205934383175',
    projectId: 'vayujal-db-for-customer-device',
    storageBucket: 'vayujal-db-for-customer-device.firebasestorage.app',
    iosBundleId: 'com.example.vayujal',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCCn87RCGPVaTNUaSfAeGYdj0bdvg0ihXY',
    appId: '1:148518126293:web:c6e59c19073b679646d85c',
    messagingSenderId: '148518126293',
    projectId: 'vayujal-db-for-device-customer',
    authDomain: 'vayujal-db-for-device-customer.firebaseapp.com',
    storageBucket: 'vayujal-db-for-device-customer.firebasestorage.app',
  );

}