import 'package:firebase_auth/firebase_auth.dart';

String describeError(Object error) {
  if (error is FirebaseAuthException) return _authMessage(error);
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'You don\'t have permission to access this data.',
      'unavailable' => 'Can\'t reach the server. Check your internet connection.',
      'failed-precondition' => 'The database isn\'t ready yet. Please try again shortly.',
      _ => error.message ?? 'Something went wrong. Please try again.',
    };
  }
  return 'Something went wrong. Please try again.';
}

String _authMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'invalid-email' => 'That email address is not valid.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Incorrect email or password.',
    'email-already-in-use' => 'An account already exists for that email.',
    'weak-password' => 'Please choose a stronger password.',
    'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
    'network-request-failed' => 'Network error. Check your internet connection.',
    'operation-not-allowed' => 'Email sign-in is not enabled for this project.',
    _ => error.message ?? 'Authentication failed. Please try again.',
  };
}
