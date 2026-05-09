import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider =
    StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);