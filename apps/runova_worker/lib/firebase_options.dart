import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Not configured for web');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCEkeovGtXDHUSONOyzQLbMoeO_YTvnMi8',
    appId: '1:762321096086:android:f6fcf015842acea3dde1b7',
    messagingSenderId: '762321096086',
    projectId: 'runova-group',
    storageBucket: 'runova-group.firebasestorage.app',
  );
}
