import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLsVEYryzTYeyJODgBna_ALcxkPx1zew4',
    appId: '1:131317260630:android:32e1e00e443268333eb6f7',
    messagingSenderId: '131317260630',
    projectId: 'campus-marketplace-7bbb7',
    storageBucket: 'campus-marketplace-7bbb7.firebasestorage.app',
  );
}
