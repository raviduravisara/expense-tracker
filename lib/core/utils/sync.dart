import 'dart:async';

Future<bool> confirmSynced(
  Future<void> write, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  try {
    await write.timeout(timeout);
    return true;
  } on TimeoutException {
    return false;
  }
}
